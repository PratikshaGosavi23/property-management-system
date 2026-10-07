-- =====================================================================
-- Property Management & Reporting System
-- File    : 01_schema.sql
-- Purpose : Create the database, tables, keys, constraints and indexes
-- Engine  : MySQL 8.0+ (InnoDB; CHECK constraints are enforced from 8.0.16)
-- =====================================================================

DROP DATABASE IF EXISTS property_mgmt;
CREATE DATABASE property_mgmt
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
USE property_mgmt;

-- ---------------------------------------------------------------------
-- 1. OWNERS : people/companies who own one or more properties
-- ---------------------------------------------------------------------
CREATE TABLE owners (
    owner_id    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    first_name  VARCHAR(50)   NOT NULL,
    last_name   VARCHAR(50)   NOT NULL,
    email       VARCHAR(100)  NOT NULL,
    phone       VARCHAR(20)   NOT NULL,
    created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_owners        PRIMARY KEY (owner_id),
    CONSTRAINT uq_owners_email  UNIQUE (email)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. PROPERTIES : each property belongs to exactly one owner
-- ---------------------------------------------------------------------
CREATE TABLE properties (
    property_id    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    owner_id       INT UNSIGNED  NOT NULL,
    property_name  VARCHAR(100)  NOT NULL,
    address_line   VARCHAR(150)  NOT NULL,
    city           VARCHAR(60)   NOT NULL,
    state          CHAR(2)       NOT NULL,
    zip_code       CHAR(5)       NOT NULL,
    property_type  ENUM('Apartment','House','Condo','Studio') NOT NULL,
    bedrooms       TINYINT UNSIGNED NOT NULL,
    bathrooms      DECIMAL(2,1)  NOT NULL,
    listed_rent    DECIMAL(10,2) NOT NULL,                  -- current asking rent / month
    status         ENUM('Available','Occupied','Under Maintenance')
                   NOT NULL DEFAULT 'Available',
    CONSTRAINT pk_properties        PRIMARY KEY (property_id),
    CONSTRAINT uq_properties_addr   UNIQUE (address_line, city, state),
    CONSTRAINT fk_properties_owner  FOREIGN KEY (owner_id)
        REFERENCES owners (owner_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,               -- cannot delete an owner who still has properties
    CONSTRAINT ck_properties_rent   CHECK (listed_rent > 0),
    CONSTRAINT ck_properties_baths  CHECK (bathrooms >= 1)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. TENANTS : people who rent properties
-- ---------------------------------------------------------------------
CREATE TABLE tenants (
    tenant_id   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    first_name  VARCHAR(50)   NOT NULL,
    last_name   VARCHAR(50)   NOT NULL,
    email       VARCHAR(100)  NOT NULL,
    phone       VARCHAR(20)   NOT NULL,
    occupation  VARCHAR(80)   NULL,
    created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tenants        PRIMARY KEY (tenant_id),
    CONSTRAINT uq_tenants_email  UNIQUE (email)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. LEASES : links a tenant to a property for a period of time
--    (resolves the many-to-many between tenants and properties over time)
-- ---------------------------------------------------------------------
CREATE TABLE leases (
    lease_id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    property_id       INT UNSIGNED  NOT NULL,
    tenant_id         INT UNSIGNED  NOT NULL,
    start_date        DATE          NOT NULL,
    end_date          DATE          NOT NULL,
    monthly_rent      DECIMAL(10,2) NOT NULL,
    security_deposit  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status            ENUM('Active','Expired','Terminated') NOT NULL DEFAULT 'Active',
    CONSTRAINT pk_leases          PRIMARY KEY (lease_id),
    CONSTRAINT fk_leases_property FOREIGN KEY (property_id)
        REFERENCES properties (property_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_leases_tenant   FOREIGN KEY (tenant_id)
        REFERENCES tenants (tenant_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_leases_dates    CHECK (end_date > start_date),
    CONSTRAINT ck_leases_rent     CHECK (monthly_rent > 0),
    CONSTRAINT ck_leases_deposit  CHECK (security_deposit >= 0),
    CONSTRAINT uq_leases_start    UNIQUE (property_id, start_date)  -- no two leases start the same day on one property
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. PAYMENTS : monthly rent ledger. One row per lease per due date.
--    amount_paid = 0 and payment_date IS NULL means "not paid yet".
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    lease_id        INT UNSIGNED  NOT NULL,
    due_date        DATE          NOT NULL,
    amount_due      DECIMAL(10,2) NOT NULL,
    amount_paid     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    payment_date    DATE          NULL,
    payment_method  ENUM('Bank Transfer','Online Portal','Credit Card','Check','Cash') NULL,
    payment_status  ENUM('Paid','Partial','Pending') NOT NULL DEFAULT 'Pending',
    CONSTRAINT pk_payments         PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_lease   FOREIGN KEY (lease_id)
        REFERENCES leases (lease_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_payments_period  UNIQUE (lease_id, due_date),     -- one rent installment per month per lease
    CONSTRAINT ck_payments_due     CHECK (amount_due > 0),
    CONSTRAINT ck_payments_paid    CHECK (amount_paid >= 0 AND amount_paid <= amount_due),
    -- the status column must always agree with the amounts
    CONSTRAINT ck_payments_status  CHECK (
           (payment_status = 'Paid'    AND amount_paid = amount_due)
        OR (payment_status = 'Partial' AND amount_paid > 0 AND amount_paid < amount_due)
        OR (payment_status = 'Pending' AND amount_paid = 0)
    ),
    -- a payment date exists if, and only if, some money was received
    CONSTRAINT ck_payments_date    CHECK (
           (amount_paid = 0 AND payment_date IS NULL)
        OR (amount_paid > 0 AND payment_date IS NOT NULL)
    )
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. MAINTENANCE_REQUESTS : repair tickets raised against a property.
--    tenant_id is NULL when the work is raised by management (e.g. vacant unit).
-- ---------------------------------------------------------------------
CREATE TABLE maintenance_requests (
    request_id      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    property_id     INT UNSIGNED  NOT NULL,
    tenant_id       INT UNSIGNED  NULL,
    category        ENUM('Plumbing','Electrical','HVAC','Appliance','Structural','Other') NOT NULL,
    description     VARCHAR(255)  NOT NULL,
    priority        ENUM('Low','Medium','High','Emergency') NOT NULL DEFAULT 'Medium',
    status          ENUM('Open','In Progress','Completed','Cancelled') NOT NULL DEFAULT 'Open',
    reported_date   DATE          NOT NULL,
    completed_date  DATE          NULL,
    cost            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    vendor_name     VARCHAR(100)  NULL,
    CONSTRAINT pk_maintenance          PRIMARY KEY (request_id),
    CONSTRAINT fk_maintenance_property FOREIGN KEY (property_id)
        REFERENCES properties (property_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_maintenance_tenant   FOREIGN KEY (tenant_id)
        REFERENCES tenants (tenant_id)
        ON UPDATE CASCADE ON DELETE SET NULL,                   -- keep the repair history if a tenant record is removed
    CONSTRAINT ck_maintenance_cost     CHECK (cost >= 0),
    CONSTRAINT ck_maintenance_dates    CHECK (completed_date IS NULL OR completed_date >= reported_date),
    -- completed_date must be filled when (and only when) the request is Completed
    CONSTRAINT ck_maintenance_done     CHECK (
           (status = 'Completed' AND completed_date IS NOT NULL)
        OR (status <> 'Completed' AND completed_date IS NULL)
    )
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Extra indexes for the columns used most in reports
-- (InnoDB already indexes every foreign key column automatically)
-- ---------------------------------------------------------------------
CREATE INDEX idx_payments_due_date   ON payments (due_date);
CREATE INDEX idx_leases_status_end   ON leases (status, end_date);
CREATE INDEX idx_maint_status_prio   ON maintenance_requests (status, priority);
