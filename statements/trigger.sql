-- ============================================================
-- SOC DBMS Mini Project — Trigger
-- File: sql/trigger.sql
-- ============================================================

USE soc_db;

-- Change delimiter so MySQL doesn't treat semicolons inside
-- the trigger body as end-of-statement
DELIMITER $$

CREATE TRIGGER trg_critical_incident_alert

    -- Fire AFTER the row is fully committed to Incidents
    AFTER INSERT ON Incidents

    -- NEW refers to the row just inserted
    FOR EACH ROW

BEGIN
    -- Only act on Critical severity incidents
    IF NEW.severity = 'Critical' THEN

        INSERT INTO Alert_Log (
            incident_id,
            alert_type,
            triggered_by,
            alert_timestamp,
            status
        ) VALUES (
            NEW.incident_id,                  -- the incident that caused this alert
            'AUTO - Critical Incident',        -- auto-generated label
            NEW.incident_id,                  -- self-reference: which incident triggered it
            NOW(),                            -- exact timestamp of alert creation
            'Unacknowledged'                  -- no human has seen this yet
        );

    END IF;
    -- If severity is NOT Critical, nothing happens; trigger exits
END$$

-- Restore normal delimiter
DELIMITER ;