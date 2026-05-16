# app/app.py
# Flask application — all routes for SOC DBMS project

from flask import Flask, render_template, request, redirect, url_for, jsonify, abort
from db import get_db
from dotenv import load_dotenv
import os
from flask import session, flash
from functools import wraps
from flask import session, redirect, url_for, flash, request

# Custom decorator to protect routes
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check if the user has an active session
        if "investigator_id" not in session:
            flash("Please log in to access this page.")
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY")
if not app.secret_key:
    raise ValueError("CRITICAL: FLASK_SECRET_KEY is missing from the environment!")

# ─────────────────────────────────────────────
# GET / — Dashboard
# ─────────────────────────────────────────────
@app.route("/")
@login_required
def dashboard():
    with get_db() as (conn, cur):
        cur.execute("SELECT COUNT(*) AS total FROM Incidents")
        total = cur.fetchone()["total"]

        cur.execute("SELECT COUNT(*) AS open FROM Incidents WHERE status = 'Open'")
        open_count = cur.fetchone()["open"]

        cur.execute("SELECT COUNT(*) AS critical FROM Alert_Log WHERE status = 'Unacknowledged'")
        critical_alerts = cur.fetchone()["critical"]

        cur.execute("SELECT COUNT(*) AS active FROM Investigators WHERE is_active = 1")
        active_inv = cur.fetchone()["active"]

        cur.execute("""
            SELECT i.incident_id, i.title, i.severity, i.status,
                   i.reported_at, tt.type_name AS threat_type
            FROM Incidents i
            JOIN Threat_Types tt ON i.threat_type_id = tt.threat_type_id
            ORDER BY i.reported_at DESC
            LIMIT 5
        """)
        recent = cur.fetchall()

    return render_template("dashboard.html",
                           total=total,
                           open_count=open_count,
                           critical_alerts=critical_alerts,
                           active_inv=active_inv,
                           recent=recent)


# ─────────────────────────────────────────────
# GET /incidents — View all incidents
# ─────────────────────────────────────────────
@app.route("/incidents")
@login_required
def incidents():
    with get_db() as (conn, cur):
        cur.execute("""
            SELECT i.incident_id, i.title, i.severity, i.status,
                   i.source_ip, i.reported_at,
                   tt.type_name AS threat_type,
                   inv.full_name AS reporter
            FROM Incidents i
            JOIN Threat_Types tt ON i.threat_type_id = tt.threat_type_id
            JOIN Investigators inv ON i.reported_by = inv.investigator_id
            ORDER BY i.reported_at DESC
        """)
        all_incidents = cur.fetchall()
    return render_template("incidents.html", incidents=all_incidents)


# ─────────────────────────────────────────────
# GET /incidents/add — Show add form
# POST /incidents/add — Submit new incident
# ─────────────────────────────────────────────
@app.route("/incidents/add", methods=["GET", "POST"])
def add_incident():
    with get_db() as (conn, cur):
        cur.execute("SELECT threat_type_id, type_name, severity FROM Threat_Types ORDER BY type_name")
        threat_types = cur.fetchall()
        cur.execute("SELECT investigator_id, full_name FROM Investigators WHERE is_active=1 ORDER BY full_name")
        investigators = cur.fetchall()

    if request.method == "POST":
        # Server-side validation
        title       = request.form.get("title", "").strip()
        description = request.form.get("description", "").strip()
        source_ip   = request.form.get("source_ip", "").strip() or None
        severity    = request.form.get("severity", "")
        threat_type = request.form.get("threat_type_id", "")
        reporter    = request.form.get("reported_by", "")

        errors = []
        if not title:
            errors.append("Title is required.")
        if severity not in ("Low", "Medium", "High", "Critical"):
            errors.append("Invalid severity.")
        if not threat_type.isdigit():
            errors.append("Please select a threat type.")
        if not reporter.isdigit():
            errors.append("Please select a reporter.")

        if errors:
            return render_template("add_incident.html",
                                   threat_types=threat_types,
                                   investigators=investigators,
                                   errors=errors,
                                   form=request.form)

        with get_db() as (conn, cur):
            cur.execute("""
                INSERT INTO Incidents
                    (title, description, source_ip, severity, status, threat_type_id, reported_by)
                VALUES (%s, %s, %s, %s, 'Open', %s, %s)
            """, (title, description, source_ip, severity, int(threat_type), int(reporter)))
            conn.commit()

        return redirect(url_for("incidents"))

    return render_template("add_incident.html",
                           threat_types=threat_types,
                           investigators=investigators,
                           errors=[],
                           form={})


# ─────────────────────────────────────────────
# GET /alerts — View all alerts
# ─────────────────────────────────────────────
@app.route("/alerts")
@login_required
def alerts():
    with get_db() as (conn, cur):
        cur.execute("""
            SELECT al.alert_id, al.alert_type, al.alert_timestamp,
                   al.status, i.incident_id, i.title, i.severity
            FROM Alert_Log al
            JOIN Incidents i ON al.incident_id = i.incident_id
            ORDER BY al.alert_timestamp DESC
        """)
        all_alerts = cur.fetchall()
    return render_template("alerts.html", alerts=all_alerts)


# ─────────────────────────────────────────────
# POST /alerts/acknowledge/<id> — Acknowledge an alert (AJAX)
# ─────────────────────────────────────────────
@app.route("/alerts/acknowledge/<int:alert_id>", methods=["POST"])
def acknowledge_alert(alert_id):
    # Strictly pull the ID from the server-side session
    investigator_id = session.get("investigator_id")
    
    # Block the request if they aren't logged in
    if not investigator_id:
        return jsonify({"success": False, "message": "Unauthorized: Please log in."}), 401

    with get_db() as (conn, cur):
        cur.execute("""
            UPDATE Alert_Log
            SET status = 'Acknowledged', acknowledged_by = %s
            WHERE alert_id = %s
        """, (investigator_id, alert_id))
        conn.commit()
        
        if cur.rowcount == 0:
            return jsonify({"success": False, "message": "Alert not found"}), 404
            
    return jsonify({"success": True, "message": "Alert acknowledged"})

# ─────────────────────────────────────────────
# GET /reports — Threat frequency + workload reports
# ─────────────────────────────────────────────
@app.route("/reports")
@login_required
def reports():
    with get_db() as (conn, cur):
        cur.execute("""
            SELECT tt.type_name AS Threat_Type, tt.severity,
                   COUNT(i.incident_id) AS Incident_Count
            FROM Threat_Types tt
            LEFT JOIN Incidents i ON tt.threat_type_id = i.threat_type_id
            GROUP BY tt.threat_type_id, tt.type_name, tt.severity
            ORDER BY Incident_Count DESC
        """)
        threat_freq = cur.fetchall()

        cur.execute("""
            SELECT inv.full_name AS Investigator, inv.department,
                   COUNT(a.incident_id) AS Open_Incidents
            FROM Investigators inv
            LEFT JOIN Assignments a ON inv.investigator_id = a.investigator_id
            LEFT JOIN Incidents i   ON a.incident_id = i.incident_id
                                   AND i.status != 'Resolved'
            GROUP BY inv.investigator_id, inv.full_name, inv.department
            ORDER BY Open_Incidents DESC
        """)
        workload = cur.fetchall()

    return render_template("reports.html", threat_freq=threat_freq, workload=workload)



#-------------------------
#login and logout
#-------------------------
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email", "").strip()
        password = request.form.get("password", "").strip()
        
        with get_db() as (conn, cur):
            # Query the database for the user
            cur.execute("""
                SELECT investigator_id, full_name, password 
                FROM Investigators 
                WHERE email = %s AND is_active = 1
            """, (email,))
            user = cur.fetchone()
            
            # Verify credentials (plaintext comparison for the mini-project)
            if user and user["password"] == password:
                # Securely store user info in the Flask session cookie
                session["investigator_id"] = user["investigator_id"]
                session["full_name"] = user["full_name"]
                return redirect(url_for("dashboard"))
            else:
                flash("Invalid email or password.")
                
    return render_template("login.html")

# GET /logout - Clear the session
@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))



# ─────────────────────────────────────────────
# GET /api/incidents — JSON endpoint for JS fetch
# ─────────────────────────────────────────────
@app.route("/api/incidents")
def api_incidents():
    # Safely get limit/offset from URL parameters (e.g., ?limit=50&offset=0)
    limit = request.args.get("limit", 50, type=int)
    offset = request.args.get("offset", 0, type=int)
    
    # Cap the limit to prevent malicious requests for millions of rows
    limit = min(limit, 100)

    with get_db() as (conn, cur):
        cur.execute("""
            SELECT i.incident_id, i.title, i.severity, i.status,
                   i.source_ip, i.reported_at,
                   tt.type_name AS threat_type
            FROM Incidents i
            JOIN Threat_Types tt ON i.threat_type_id = tt.threat_type_id
            ORDER BY i.reported_at DESC
            LIMIT %s OFFSET %s
        """, (limit, offset))
        rows = cur.fetchall()
    # Convert datetime objects to strings for JSON serialization
    for row in rows:
        if row.get("reported_at"):
            row["reported_at"] = str(row["reported_at"])
    return jsonify(rows)


# ─────────────────────────────────────────────
# Custom error pages
# ─────────────────────────────────────────────
@app.errorhandler(404)
def not_found(e):
    return render_template("404.html"), 404


@app.errorhandler(500)
def server_error(e):
    return render_template("500.html"), 500


# ─────────────────────────────────────────────
# Run
# ─────────────────────────────────────────────
if __name__ == "__main__":
    # Safely determine debug mode from the environment (.env)
    is_debug = os.getenv("FLASK_DEBUG", "False").lower() == "true"
    
    # Use 127.0.0.1 (localhost) for local testing. 
    # Only use 0.0.0.0 if running inside a Docker container.
    app.run(debug=is_debug, host="127.0.0.1", port=5000)