// ============================================================
// SOC Logger — Frontend JavaScript
// ============================================================

// ─────────────────────────────────────────────
// 1. Acknowledge Alert (AJAX fetch call)
// Called from the ACK button in alerts.html
// ─────────────────────────────────────────────
async function acknowledgeAlert(alertId) {
    const btn = event.target;
    btn.disabled = true;
    btn.textContent = '...';

    try {
        const response = await fetch(`/alerts/acknowledge/${alertId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ investigator_id: 1 })  // hardcoded for demo
        });

        const data = await response.json();

        if (data.success) {
            // Update status cell without page reload
            const statusCell = document.getElementById(`alert-status-${alertId}`);
            statusCell.innerHTML = '<span class="pill pill-acknowledged">Acknowledged</span>';
            btn.textContent = 'Done';
            btn.style.opacity = '0.4';
        } else {
            alert('Failed to acknowledge alert: ' + data.message);
            btn.disabled = false;
            btn.textContent = 'ACK';
        }
    } catch (err) {
        console.error('Network error:', err);
        alert('Network error. Please try again.');
        btn.disabled = false;
        btn.textContent = 'ACK';
    }
}


// ─────────────────────────────────────────────
// 2. Client-side form validation for Add Incident
// ─────────────────────────────────────────────
const form = document.getElementById('add-incident-form');
if (form) {
    form.addEventListener('submit', function (e) {
        const title      = document.getElementById('title').value.trim();
        const severity   = document.getElementById('severity').value;
        const threatType = document.getElementById('threat_type_id').value;
        const reporter   = document.getElementById('reported_by').value;

        const errors = [];

        if (!title) errors.push('Incident title is required.');
        if (!severity) errors.push('Please select a severity level.');
        if (!threatType) errors.push('Please select a threat type.');
        if (!reporter) errors.push('Please select a reporter.');

        // Basic IP format check (optional field)
        const ipField = document.getElementById('source_ip').value.trim();
        if (ipField) {
            const ipv4Pattern = /^(\d{1,3}\.){3}\d{1,3}$/;
            if (!ipv4Pattern.test(ipField)) {
                errors.push('Source IP must be a valid IPv4 address (e.g. 192.168.1.1).');
            }
        }

        if (errors.length > 0) {
            e.preventDefault();  // stop form from submitting
            // Display errors
            let existingList = form.querySelector('.client-errors');
            if (existingList) existingList.remove();
            const ul = document.createElement('ul');
            ul.className = 'error-list client-errors';
            errors.forEach(msg => {
                const li = document.createElement('li');
                li.textContent = msg;
                ul.appendChild(li);
            });
            form.insertBefore(ul, form.firstChild);
            window.scrollTo(0, 0);
        }
    });
}


// ─────────────────────────────────────────────
// 3. Dashboard auto-refresh with countdown timer
// Only runs on the dashboard page
// ─────────────────────────────────────────────
const countdownEl = document.getElementById('countdown');
if (countdownEl) {
    let seconds = 30;

    const interval = setInterval(() => {
        seconds--;
        countdownEl.textContent = seconds;
        if (seconds <= 0) {
            clearInterval(interval);
            location.reload();  // refresh the whole dashboard page
        }
    }, 1000);
}
async function acknowledgeAlert(alertId) {
    const btn = event.target;
    // ... [existing code] ...
    } catch (err) {
        console.error('Network error:', err);
        alert('Network error. Please try again.');
        btn.disabled = false;
        btn.textContent = 'ACK';
    }
} // <-- FIX: Add missing closing brace for the function

// ... [existing form code] ...
const form = document.getElementById('add-incident-form');
if (form) {
    form.addEventListener('submit', function (e) {
        // ... [existing validation code] ...
            form.insertBefore(ul, form.firstChild);
            window.scrollTo(0, 0);
        }
    });
} // <-- FIX: Add missing closing brace for the if block