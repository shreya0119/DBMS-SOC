-- ============================================================
-- SOC DBMS Mini Project — ACID Transaction
-- Scenario: Resolving incident #2 (DDoS on Public API)
-- ============================================================

USE soc_db;

-- ─────────────────────────────────
-- SUCCESSFUL TRANSACTION (COMMIT)
-- ─────────────────────────────────
START TRANSACTION;

    -- Step 1: Mark the incident as Resolved
    UPDATE Incidents
    SET status = 'Resolved'
    WHERE incident_id = 2;

    -- Step 2: Log the mitigation action (must happen atomically with step 1)
    INSERT INTO Mitigation_Log (incident_id, action_taken, action_taken_at, resolved_by)
    VALUES (
        2,
        'Rate limiting enforced at CDN level; botnet IPs blocklisted; ISP contacted for upstream filtering.',
        NOW(),
        3  -- Rohan Mehta resolved it
    );

-- If both steps succeeded, permanently save changes
COMMIT;

-- Verify both changes happened
SELECT incident_id, title, status FROM Incidents WHERE incident_id = 2;
SELECT * FROM Mitigation_Log WHERE incident_id = 2;


-- ─────────────────────────────────
-- ROLLBACK SIMULATION (Failure)
-- ─────────────────────────────────
START TRANSACTION;

    UPDATE Incidents
    SET status = 'Resolved'
    WHERE incident_id = 5;

    -- Simulate error: insert into Mitigation_Log with invalid resolved_by (investigator 999 doesn't exist)
    INSERT INTO Mitigation_Log (incident_id, action_taken, action_taken_at, resolved_by)
    VALUES (5, 'Simulated bad entry', NOW(), 999);  -- FK violation — investigator 999 not found

-- Because of the FK error above, we roll back ALL changes in this transaction
-- Incident #5 remains 'In Progress', no mitigation log created
ROLLBACK;

-- Confirm incident #5 is still 'In Progress' (not 'Resolved')
SELECT incident_id, title, status FROM Incidents WHERE incident_id = 5;


-- ─────────────────────────────────
-- SAVEPOINT Example
-- ─────────────────────────────────
START TRANSACTION;

    -- First update: safe to keep even if second fails
    UPDATE Incidents SET status = 'In Progress' WHERE incident_id = 9;

    SAVEPOINT after_status_update;  -- mark this point as a safe checkpoint

    -- Attempt second operation (might fail)
    INSERT INTO Mitigation_Log (incident_id, action_taken, action_taken_at, resolved_by)
    VALUES (9, 'Partial action taken — investigation ongoing', NOW(), 999);  -- bad FK

    -- If second fails, roll back ONLY to the savepoint
    -- The status update above is preserved
    ROLLBACK TO SAVEPOINT after_status_update;

-- Commit just the status update
COMMIT;

SELECT incident_id, title, status FROM Incidents WHERE incident_id = 9;