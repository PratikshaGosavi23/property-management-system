-- =====================================================================
-- File    : 05_transactions.sql
-- Purpose : Multi-step business operations wrapped in transactions so
--           the data is never left half-updated (ACID: atomicity).
-- Run     : LAST. Transactions 1 and 3 change data and are COMMITTED.
--           To re-run everything from scratch, run 01 and 02 again.
-- =====================================================================
USE property_mgmt;

-- Transactions need InnoDB (already used by every table) and
-- autocommit turned off for the duration of each START TRANSACTION block.


-- =====================================================================
-- TRANSACTION 1 : Onboard a new tenant (COMMIT)
-- Business rule: signing a lease must (a) create the lease,
-- (b) generate the first rent invoice, and (c) mark the property
-- Occupied. If any step fails, none of them should be saved.
-- Scenario: Chloe Dubois (tenant 13) leases Maple Court 201 (property 3)
-- =====================================================================
SELECT 'BEFORE' AS stage, property_id, property_name, status
FROM   properties WHERE property_id = 3;

START TRANSACTION;

-- Lock the property row so nobody else can lease it at the same moment
SELECT status INTO @current_status
FROM   properties
WHERE  property_id = 3
FOR UPDATE;

-- (a) Create the lease only if the property is really Available
INSERT INTO leases (property_id, tenant_id, start_date, end_date,
                    monthly_rent, security_deposit, status)
SELECT  property_id, 13, '2025-07-01', '2026-06-30', 1550.00, 1550.00, 'Active'
FROM    properties
WHERE   property_id = 3
  AND   status = 'Available';
SET @rows_inserted = ROW_COUNT();     -- 1 = lease created, 0 = property was not available

-- (b) First rent invoice, paid in advance by the tenant
INSERT INTO payments (lease_id, due_date, amount_due, amount_paid,
                      payment_date, payment_method, payment_status)
SELECT  lease_id, '2025-07-01', 1550.00, 1550.00, '2025-06-28', 'Bank Transfer', 'Paid'
FROM    leases
WHERE   property_id = 3 AND tenant_id = 13 AND status = 'Active';

-- (c) Flip the property status
UPDATE  properties
SET     status = 'Occupied'
WHERE   property_id = 3 AND status = 'Available';

-- Check before saving. If @rows_inserted were 0 we would run ROLLBACK instead.
SELECT @rows_inserted AS lease_rows_inserted;
COMMIT;

SELECT 'AFTER' AS stage, p.property_id, p.property_name, p.status,
       l.lease_id, l.start_date, l.monthly_rent
FROM   properties p
JOIN   leases l ON l.property_id = p.property_id AND l.status = 'Active'
WHERE  p.property_id = 3;


-- =====================================================================
-- TRANSACTION 2 : Terminate a lease early, review, then ROLLBACK
-- Demonstrates SAVEPOINT and ROLLBACK. We "try" the termination of
-- lease 8 (Pine Hollow Cottage), inspect the result, and then undo it
-- because the tenant agreed to renew. Nothing is saved.
-- =====================================================================
START TRANSACTION;

UPDATE leases     SET status = 'Terminated' WHERE lease_id = 8;
UPDATE properties SET status = 'Available'  WHERE property_id = 11;

SAVEPOINT after_termination;

-- Second step: also pull the lease end date forward to today
UPDATE leases SET end_date = '2025-06-30' WHERE lease_id = 8;

-- Inspect the in-flight (uncommitted) state
SELECT 'INSIDE TRANSACTION' AS stage, l.lease_id, l.status AS lease_status,
       p.property_name, p.status AS property_status
FROM   leases l JOIN properties p ON p.property_id = l.property_id
WHERE  l.lease_id = 8;

-- Undo only the end-date change (partial rollback) ...
ROLLBACK TO SAVEPOINT after_termination;
-- ... then undo everything because the tenant is renewing
ROLLBACK;

SELECT 'AFTER ROLLBACK' AS stage, l.lease_id, l.status AS lease_status,
       p.property_name, p.status AS property_status
FROM   leases l JOIN properties p ON p.property_id = l.property_id
WHERE  l.lease_id = 8;


-- =====================================================================
-- TRANSACTION 3 : Close a maintenance job and release the unit (COMMIT)
-- The repair record and the property status must change together:
-- request 9 (water damage in vacant unit Riverside Condo 7A) is done.
-- =====================================================================
START TRANSACTION;

UPDATE maintenance_requests
SET    status         = 'Completed',
       completed_date = '2025-06-27',
       cost           = 2650.00           -- final invoice from the vendor
WHERE  request_id = 9
  AND  status = 'In Progress';

-- Release the property only if no other repair is still open on it
UPDATE properties p
SET    p.status = 'Available'
WHERE  p.property_id = 7
  AND  p.status = 'Under Maintenance'
  AND  NOT EXISTS (SELECT 1
                   FROM   maintenance_requests m
                   WHERE  m.property_id = p.property_id
                     AND  m.status IN ('Open', 'In Progress'));

COMMIT;

SELECT p.property_name, p.status AS property_status,
       m.request_id, m.status AS request_status, m.completed_date, m.cost
FROM   properties p
JOIN   maintenance_requests m ON m.property_id = p.property_id
WHERE  m.request_id = 9;
