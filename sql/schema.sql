-- ============================================================
-- SOC DBMS Mini Project — Schema (DDL)
-- File: sql/schema.sql
-- Run: mysql -u root -p < sql/schema.sql
-- ============================================================

DROP DATABASE IF EXISTS soc_db;
CREATE DATABASE soc_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE soc_db;

-- ──────────────────────────────────────────
-- TABLE 1: Investigators
-- Parent table — no FK dependencies
-- ──────────────────────────────────────────
CREATE TABLE Investigators (
    investigator_id   INT            NOT NULL AUTO_INCREMENT,
    full_name         VARCHAR(100)   NOT NULL,
    email             VARCHAR(150)   NOT NULL UNIQUE,        -- unique login identity
    department        VARCHAR(80)    NOT NULL,
    phone             VARCHAR(20)    DEFAULT NULL,
    hired_at          DATE           NOT NULL DEFAULT (CURDATE()),
    is_active         TINYINT(1)     NOT NULL DEFAULT 1,     -- 1=active, 0=inactive

    PRIMARY KEY (investigator_id)
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- TABLE 2: Threat_Types
-- Lookup/reference table — no FK dependencies
-- ──────────────────────────────────────────
CREATE TABLE Threat_Types (
    threat_type_id    INT            NOT NULL AUTO_INCREMENT,
    type_name         VARCHAR(80)    NOT NULL UNIQUE,
    severity          ENUM('Low','Medium','High','Critical') NOT NULL,
    description       TEXT           DEFAULT NULL,

    PRIMARY KEY (threat_type_id)
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- TABLE 3: Incidents
-- Central table — references Threat_Types + Investigators
-- ──────────────────────────────────────────
CREATE TABLE Incidents (
    incident_id       INT            NOT NULL AUTO_INCREMENT,
    title             VARCHAR(200)   NOT NULL,
    description       TEXT           DEFAULT NULL,
    source_ip         VARCHAR(45)    DEFAULT NULL,           -- supports IPv4 and IPv6
    severity          ENUM('Low','Medium','High','Critical') NOT NULL,
    status            ENUM('Open','In Progress','Resolved')  NOT NULL DEFAULT 'Open',
    reported_at       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    threat_type_id    INT            NOT NULL,
    reported_by       INT            NOT NULL,               -- investigator who logged this

    PRIMARY KEY (incident_id),

    -- When a threat type is deleted, prevent deletion if incidents reference it
    CONSTRAINT fk_incident_threat
        FOREIGN KEY (threat_type_id)
        REFERENCES Threat_Types(threat_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- When an investigator is deleted, keep incident record but nullify reference
    CONSTRAINT fk_incident_reporter
        FOREIGN KEY (reported_by)
        REFERENCES Investigators(investigator_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- TABLE 4: Assignments
-- Junction table for M:N between Incidents and Investigators
-- ──────────────────────────────────────────
CREATE TABLE Assignments (
    assignment_id     INT            NOT NULL AUTO_INCREMENT,
    incident_id       INT            NOT NULL,
    investigator_id   INT            NOT NULL,
    assigned_at       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    role              VARCHAR(80)    DEFAULT 'Lead Analyst', -- e.g. Lead, Support, Forensics

    PRIMARY KEY (assignment_id),

    -- Prevent same investigator being assigned twice to same incident
    UNIQUE KEY uq_assignment (incident_id, investigator_id),

    CONSTRAINT fk_assignment_incident
        FOREIGN KEY (incident_id)
        REFERENCES Incidents(incident_id)
        ON DELETE CASCADE    -- if incident deleted, remove assignments too
        ON UPDATE CASCADE,

    CONSTRAINT fk_assignment_investigator
        FOREIGN KEY (investigator_id)
        REFERENCES Investigators(investigator_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- TABLE 5: IOCs (Indicators of Compromise)
-- ──────────────────────────────────────────
CREATE TABLE IOCs (
    ioc_id            INT            NOT NULL AUTO_INCREMENT,
    incident_id       INT            NOT NULL,
    ioc_type          ENUM('IP','Hash','Domain','URL','Email') NOT NULL,
    ioc_value         VARCHAR(512)   NOT NULL,               -- hashes can be long
    description       VARCHAR(255)   DEFAULT NULL,
    added_at          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (ioc_id),

    CONSTRAINT fk_ioc_incident
        FOREIGN KEY (incident_id)
        REFERENCES Incidents(incident_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- TABLE 6: Alert_Log
-- Auto-populated by trigger for Critical incidents
-- ──────────────────────────────────────────
CREATE TABLE Alert_Log (
    alert_id          INT            NOT NULL AUTO_INCREMENT,
    incident_id       INT            NOT NULL,
    alert_type        VARCHAR(100)   NOT NULL,               -- e.g. 'AUTO - Critical Incident'
    triggered_by      INT            NOT NULL,               -- stores the incident_id that caused it
    alert_timestamp   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status            ENUM('Unacknowledged','Acknowledged','Escalated') NOT NULL DEFAULT 'Unacknowledged',
    acknowledged_by   INT            DEFAULT NULL,           -- investigator_id who acknowledged

    PRIMARY KEY (alert_id),

    CONSTRAINT fk_alert_incident
        FOREIGN KEY (incident_id)
        REFERENCES Incidents(incident_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_alert_acknowledger
        FOREIGN KEY (acknowledged_by)
        REFERENCES Investigators(investigator_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- TABLE 7: Mitigation_Log
-- Records remediation actions; updated atomically with Incidents.status
-- ──────────────────────────────────────────
CREATE TABLE Mitigation_Log (
    mitigation_id     INT            NOT NULL AUTO_INCREMENT,
    incident_id       INT            NOT NULL,
    action_taken      TEXT           NOT NULL,               -- description of what was done
    action_taken_at   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_by       INT            NOT NULL,               -- investigator_id

    PRIMARY KEY (mitigation_id),

    CONSTRAINT fk_mitigation_incident
        FOREIGN KEY (incident_id)
        REFERENCES Incidents(incident_id)
        ON DELETE RESTRICT   -- don't auto-delete mitigation records if incident deleted
        ON UPDATE CASCADE,

    CONSTRAINT fk_mitigation_resolver
        FOREIGN KEY (resolved_by)
        REFERENCES Investigators(investigator_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- Verification
-- ──────────────────────────────────────────
SHOW TABLES;

DESCRIBE Investigators;
DESCRIBE Threat_Types;
DESCRIBE Incidents;
DESCRIBE Assignments;
DESCRIBE IOCs;
DESCRIBE Alert_Log;
DESCRIBE Mitigation_Log;