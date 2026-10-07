-- =====================================================================
-- File    : 06_constraint_tests.sql
-- Purpose : Prove that the database rejects bad data.
-- Run     : in MySQL Workbench run each statement on its own, or from the
--           command line:  mysql -u root -p --force < 06_constraint_tests.sql
--           (--force keeps going after each expected error)
-- EVERY statement below is EXPECTED TO FAIL. The expected error is in
-- the comment above it. Nothing is changed in the database.
-- =====================================================================
USE property_mgmt;

-- 1. Foreign key: lease for a property that does not exist
--    ERROR 1452: Cannot add or update a child row: a foreign key constraint fails
INSERT INTO leases (property_id, tenant_id, start_date, end_date, monthly_rent)
VALUES (999, 1, '2025-07-01', '2026-06-30', 1000.00);

-- 2. Foreign key RESTRICT: cannot delete an owner who still owns properties
--    ERROR 1451: Cannot delete or update a parent row
DELETE FROM owners WHERE owner_id = 1;

-- 3. UNIQUE: duplicate tenant email
--    ERROR 1062: Duplicate entry for key 'uq_tenants_email'
INSERT INTO tenants (first_name, last_name, email, phone)
VALUES ('Test', 'User', 'aarav.shah@example.com', '000-000-0000');

-- 4. CHECK: lease ends before it starts
--    ERROR 3819: Check constraint 'ck_leases_dates' is violated
INSERT INTO leases (property_id, tenant_id, start_date, end_date, monthly_rent)
VALUES (3, 13, '2025-07-01', '2025-01-01', 1000.00);

-- 5. CHECK: payment larger than the amount due
--    ERROR 3819: Check constraint 'ck_payments_paid' is violated
UPDATE payments SET amount_paid = 99999.00 WHERE payment_id = 1;

-- 6. CHECK: status says 'Paid' but the money has not arrived
--    ERROR 3819: Check constraint 'ck_payments_status' is violated
UPDATE payments SET payment_status = 'Paid' WHERE payment_id = 18;   -- unpaid June invoice

-- 7. CHECK: a Completed repair must have a completion date
--    ERROR 3819: Check constraint 'ck_maintenance_done' is violated
UPDATE maintenance_requests SET status = 'Completed' WHERE request_id = 7;

-- 8. UNIQUE: two rent invoices for the same lease and month
--    ERROR 1062: Duplicate entry for key 'uq_payments_period'
INSERT INTO payments (lease_id, due_date, amount_due)
VALUES (1, '2025-06-01', 1500.00);

-- 9. ENUM: invalid property type
--    ERROR 1265 / 1366: Data truncated / Incorrect value for column 'property_type'
INSERT INTO properties (owner_id, property_name, address_line, city, state, zip_code,
                        property_type, bedrooms, bathrooms, listed_rent)
VALUES (1, 'Bad Row', '1 Test St', 'Austin', 'TX', '78701', 'Castle', 3, 2.0, 1000.00);
