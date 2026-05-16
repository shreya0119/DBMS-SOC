-- ============================================================
-- SOC DBMS Mini Project — Sample Data (DML)
-- File: sql/data.sql
-- Run AFTER schema.sql: mysql -u root -p soc_db < sql/data.sql
-- ============================================================

USE soc_db;

-- ──────────────────────────────────────────
-- 1. Investigators (4 rows)
-- ──────────────────────────────────────────
INSERT INTO Investigators (full_name, email, department, phone, hired_at) VALUES
('Arjun Sharma',   'arjun.sharma@soc.local',   'Tier 1 Analyst',      '9876543210', '2022-06-01'),
('Priya Nair',     'priya.nair@soc.local',      'Forensics',           '9845612300', '2021-03-15'),
('Rohan Mehta',    'rohan.mehta@soc.local',     'Threat Intelligence', '9900112233', '2023-01-10'),
('Sneha Iyer',     'sneha.iyer@soc.local',      'Incident Response',   '9812345678', '2020-09-20');

-- ──────────────────────────────────────────
-- 2. Threat_Types (6 rows)
-- ──────────────────────────────────────────
INSERT INTO Threat_Types (type_name, severity, description) VALUES
('Malware',        'High',     'Malicious software designed to disrupt, damage, or gain access'),
('DDoS',           'High',     'Distributed Denial of Service — overwhelms server with traffic'),
('SQL Injection',  'Critical', 'Attacker injects SQL to manipulate database queries'),
('Brute Force',    'Medium',   'Repeated login attempts to guess credentials'),
('Phishing',       'Medium',   'Fraudulent emails/sites to steal credentials or install malware'),
('Ransomware',     'Critical', 'Encrypts victim data and demands ransom for decryption key');

-- ──────────────────────────────────────────
-- 3. Incidents (10 rows — 2 Critical for trigger testing)
-- ──────────────────────────────────────────
INSERT INTO Incidents (title, description, source_ip, severity, status, reported_at, threat_type_id, reported_by) VALUES
('Malware on HR Server',
    'Trojan detected on HR-SRV-01 via endpoint agent alert.',
    '10.0.1.45', 'High', 'In Progress', '2024-04-01 09:15:00', 1, 1),

('DDoS on Public API',
    'API gateway receiving 500k requests/minute from botnet.',
    '203.0.113.0', 'High', 'Open', '2024-04-02 14:30:00', 2, 2),

('SQL Injection on Login Portal',
    'Union-based SQL injection detected in login form — DB exfiltration possible.',
    '198.51.100.77', 'Critical', 'Open', '2024-04-03 08:00:00', 3, 3),

('Brute Force on VPN',
    '4000+ failed SSH login attempts from single external IP.',
    '185.234.219.5', 'Medium', 'Resolved', '2024-04-04 11:45:00', 4, 4),

('Phishing Campaign — Finance Dept',
    'Targeted spear-phishing emails impersonating CFO sent to 15 finance staff.',
    NULL, 'Medium', 'In Progress', '2024-04-05 10:00:00', 5, 1),

('Ransomware on File Server',
    'File server FS-02 encrypted. Ransom note found. All shares locked.',
    '172.16.0.10', 'Critical', 'Open', '2024-04-06 03:22:00', 6, 2),

('Malware — USB Propagation',
    'Worm spreading via USB drives across manufacturing floor workstations.',
    '192.168.5.0', 'High', 'In Progress', '2024-04-07 13:00:00', 1, 3),

('SQL Injection Attempt — CRM',
    'Error-based SQLi attempt on CRM customer search endpoint. Blocked by WAF.',
    '91.108.4.100', 'High', 'Resolved', '2024-04-08 16:30:00', 3, 4),

('Brute Force on Admin Panel',
    'Web admin panel targeted; account lockout triggered after 100 attempts.',
    '5.188.206.14', 'Medium', 'Open', '2024-04-09 09:00:00', 4, 1),

('Phishing — Executive Impersonation',
    'CEO email spoofed; wire transfer request sent to accounts payable.',
    NULL, 'Medium', 'In Progress', '2024-04-10 08:30:00', 5, 2);

-- ──────────────────────────────────────────
-- 4. Assignments (8 rows)
-- ──────────────────────────────────────────
INSERT INTO Assignments (incident_id, investigator_id, role) VALUES
(1, 1, 'Lead Analyst'),
(1, 2, 'Forensics Support'),
(2, 3, 'Lead Analyst'),
(3, 4, 'Lead Analyst'),
(3, 3, 'Threat Intelligence'),
(5, 1, 'Lead Analyst'),
(6, 2, 'Incident Response Lead'),
(7, 3, 'Lead Analyst');

-- ──────────────────────────────────────────
-- 5. IOCs (10 rows)
-- ──────────────────────────────────────────
INSERT INTO IOCs (incident_id, ioc_type, ioc_value, description) VALUES
(1, 'Hash',   'd41d8cd98f00b204e9800998ecf8427e', 'MD5 hash of dropped payload'),
(1, 'Domain', 'c2.malicious-example.net',          'C2 command-and-control domain'),
(2, 'IP',     '203.0.113.0',                       'Primary botnet source IP'),
(2, 'IP',     '198.51.100.200',                    'Secondary botnet relay node'),
(3, 'IP',     '198.51.100.77',                     'Source IP of SQLi requests'),
(3, 'URL',    'https://victim.site/login?id=1 OR 1=1--', 'Injected payload URL'),
(5, 'Email',  'cfo.fake@soc-phish.com',            'Spoofed sender email address'),
(6, 'Hash',   'aabbcc1122334455667788990011aabb', 'Ransomware executable SHA256'),
(6, 'Domain', 'ransom-pay.onion.example.com',      'Ransom payment site (TOR)'),
(7, 'IP',     '192.168.5.99',                      'Patient-zero USB insertion workstation');

-- ──────────────────────────────────────────
-- 6. Mitigation_Log (5 rows — resolved incidents only)
-- ──────────────────────────────────────────
INSERT INTO Mitigation_Log (incident_id, action_taken, action_taken_at, resolved_by) VALUES
(4, 'Blocked source IP at firewall; enabled CAPTCHA on VPN portal; reset affected accounts.',
    '2024-04-04 15:00:00', 4),
(8, 'WAF rule updated; input sanitization patched in CRM code; penetration test scheduled.',
    '2024-04-09 10:00:00', 4),
(4, 'Follow-up: MFA enforced on all VPN accounts as permanent control.',
    '2024-04-05 09:00:00', 1),
(8, 'Follow-up: Full code review of CRM application completed; no other SQLi vectors found.',
    '2024-04-10 11:00:00', 2),
(8, 'SIEM rule updated to alert on SQLi patterns matching this attack signature.',
    '2024-04-10 14:00:00', 3);

-- ──────────────────────────────────────────
-- Verification queries
-- ──────────────────────────────────────────
SELECT * FROM Investigators;
SELECT * FROM Threat_Types;
SELECT * FROM Incidents;
SELECT * FROM Assignments;
SELECT * FROM IOCs;
SELECT * FROM Alert_Log;    -- should have 2 auto-rows IF trigger is installed; 0 if not yet
SELECT * FROM Mitigation_Log;