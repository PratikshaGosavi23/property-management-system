-- =====================================================================
-- File    : 02_sample_data.sql
-- Purpose : Load realistic sample data (fictional people and addresses)
-- Scenario: A small property management company. "Today" for all
--           reports is 2025-06-30 (see @report_date in the query files).
-- =====================================================================
USE property_mgmt;

-- ---------------------------------------------------------------------
-- OWNERS (5)
-- ---------------------------------------------------------------------
INSERT INTO owners (owner_id, first_name, last_name, email, phone) VALUES
(1, 'Rajesh',  'Mehta',   'rajesh.mehta@example.com',   '512-555-0101'),
(2, 'Sandra',  'Collins', 'sandra.collins@example.com', '512-555-0102'),
(3, 'Priya',   'Nair',    'priya.nair@example.com',     '512-555-0103'),
(4, 'Michael', 'Brennan', 'michael.brennan@example.com','512-555-0104'),
(5, 'Hannah',  'Cho',     'hannah.cho@example.com',     '512-555-0105');

-- ---------------------------------------------------------------------
-- PROPERTIES (12)
-- Status reflects the lease data below:
--   Occupied = has an Active lease, Available = vacant and ready,
--   Under Maintenance = vacant with major repair work in progress
-- ---------------------------------------------------------------------
INSERT INTO properties
(property_id, owner_id, property_name, address_line, city, state, zip_code, property_type, bedrooms, bathrooms, listed_rent, status) VALUES
(1,  1, 'Maple Court 101',      '101 Maple Court',        'Austin',      'TX', '78701', 'Apartment', 2, 1.0, 1500.00, 'Occupied'),
(2,  1, 'Maple Court 102',      '102 Maple Court',        'Austin',      'TX', '78701', 'Apartment', 1, 1.0, 1200.00, 'Occupied'),
(3,  1, 'Maple Court 201',      '201 Maple Court',        'Austin',      'TX', '78701', 'Apartment', 2, 1.0, 1550.00, 'Available'),
(4,  2, 'Lakeview Villa',       '45 Lakeview Drive',      'Austin',      'TX', '78703', 'House',     4, 3.0, 2800.00, 'Occupied'),
(5,  2, 'Oak Street Home',      '88 Oak Street',          'Round Rock',  'TX', '78664', 'House',     3, 2.0, 2200.00, 'Occupied'),
(6,  3, 'Riverside Condo 5B',   '500 Riverside Blvd 5B',  'Austin',      'TX', '78702', 'Condo',     2, 2.0, 1900.00, 'Occupied'),
(7,  3, 'Riverside Condo 7A',   '500 Riverside Blvd 7A',  'Austin',      'TX', '78702', 'Condo',     1, 1.0, 1400.00, 'Under Maintenance'),
(8,  4, 'Downtown Studio 12',   '12 Congress Ave',        'Austin',      'TX', '78701', 'Studio',    0, 1.0, 1100.00, 'Occupied'),
(9,  4, 'Downtown Studio 14',   '14 Congress Ave',        'Austin',      'TX', '78701', 'Studio',    0, 1.0, 1050.00, 'Available'),
(10, 5, 'Cedar Ridge Townhome', '230 Cedar Ridge Road',   'Cedar Park',  'TX', '78613', 'House',     3, 2.5, 2400.00, 'Occupied'),
(11, 5, 'Pine Hollow Cottage',  '17 Pine Hollow Lane',    'Cedar Park',  'TX', '78613', 'House',     2, 1.0, 1650.00, 'Occupied'),
(12, 3, 'Harbor Point 3C',      '9 Harbor Point Way 3C',  'Round Rock',  'TX', '78665', 'Condo',     3, 2.0, 2300.00, 'Occupied');

-- ---------------------------------------------------------------------
-- TENANTS (13)  -- tenant 13 has no lease yet (new applicant)
-- ---------------------------------------------------------------------
INSERT INTO tenants (tenant_id, first_name, last_name, email, phone, occupation) VALUES
(1,  'Aarav',    'Shah',     'aarav.shah@example.com',     '737-555-0201', 'Software Engineer'),
(2,  'Emily',    'Carter',   'emily.carter@example.com',   '737-555-0202', 'Nurse'),
(3,  'Daniel',   'Okafor',   'daniel.okafor@example.com',  '737-555-0203', 'Architect'),
(4,  'Sofia',    'Martinez', 'sofia.martinez@example.com', '737-555-0204', 'Teacher'),
(5,  'Liam',     'Johnson',  'liam.johnson@example.com',   '737-555-0205', 'Sales Manager'),
(6,  'Neha',     'Kapoor',   'neha.kapoor@example.com',    '737-555-0206', 'Graphic Designer'),
(7,  'Oliver',   'Wright',   'oliver.wright@example.com',  '737-555-0207', 'Accountant'),
(8,  'Grace',    'Lee',      'grace.lee@example.com',      '737-555-0208', 'Pharmacist'),
(9,  'Marcus',   'Reed',     'marcus.reed@example.com',    '737-555-0209', 'Electrician'),
(10, 'Isabella', 'Rossi',    'isabella.rossi@example.com', '737-555-0210', 'Chef'),
(11, 'Ethan',    'Brooks',   'ethan.brooks@example.com',   '737-555-0211', 'Data Analyst'),
(12, 'Noah',     'Patel',    'noah.patel@example.com',     '737-555-0212', 'Student'),
(13, 'Chloe',    'Dubois',   'chloe.dubois@example.com',   '737-555-0213', 'Marketing Specialist');

-- ---------------------------------------------------------------------
-- LEASES (12): 9 active, 2 expired, 1 terminated early
-- ---------------------------------------------------------------------
INSERT INTO leases
(lease_id, property_id, tenant_id, start_date, end_date, monthly_rent, security_deposit, status) VALUES
(1,  1,  1,  '2024-09-01', '2025-08-31', 1500.00, 1500.00, 'Active'),
(2,  2,  2,  '2025-01-01', '2025-12-31', 1200.00, 1200.00, 'Active'),
(3,  4,  3,  '2024-10-01', '2025-09-30', 2800.00, 2800.00, 'Active'),
(4,  5,  4,  '2025-02-01', '2026-01-31', 2200.00, 2200.00, 'Active'),
(5,  6,  5,  '2024-12-01', '2025-11-30', 1900.00, 1900.00, 'Active'),
(6,  8,  6,  '2025-01-01', '2025-12-31', 1100.00, 1100.00, 'Active'),
(7,  10, 7,  '2025-03-01', '2026-02-28', 2400.00, 2400.00, 'Active'),
(8,  11, 8,  '2024-08-01', '2025-07-31', 1650.00, 1650.00, 'Active'),
(9,  12, 9,  '2025-04-01', '2026-03-31', 2300.00, 2300.00, 'Active'),
(10, 3,  10, '2023-09-01', '2024-08-31', 1450.00, 1450.00, 'Expired'),
(11, 7,  11, '2024-01-01', '2024-12-31', 1350.00, 1350.00, 'Expired'),
(12, 9,  12, '2024-03-01', '2025-03-31', 1000.00, 1000.00, 'Terminated');

-- ---------------------------------------------------------------------
-- PAYMENTS (rent ledger, Jan-Jun 2025 plus a little history)
-- Columns: lease, due date, amount due, amount paid, paid on, method, status
-- Includes on-time, late (after the 5th), partial and unpaid rent so the
-- reports have something meaningful to show.
-- ---------------------------------------------------------------------
INSERT INTO payments
(lease_id, due_date, amount_due, amount_paid, payment_date, payment_method, payment_status) VALUES
-- Lease 1 (1500) : one late payment in May
(1, '2025-01-01', 1500.00, 1500.00, '2025-01-01', 'Bank Transfer', 'Paid'),
(1, '2025-02-01', 1500.00, 1500.00, '2025-02-01', 'Bank Transfer', 'Paid'),
(1, '2025-03-01', 1500.00, 1500.00, '2025-03-04', 'Bank Transfer', 'Paid'),
(1, '2025-04-01', 1500.00, 1500.00, '2025-04-01', 'Bank Transfer', 'Paid'),
(1, '2025-05-01', 1500.00, 1500.00, '2025-05-10', 'Bank Transfer', 'Paid'),
(1, '2025-06-01', 1500.00, 1500.00, '2025-06-01', 'Bank Transfer', 'Paid'),
-- Lease 2 (1200) : always on time
(2, '2025-01-01', 1200.00, 1200.00, '2025-01-02', 'Online Portal', 'Paid'),
(2, '2025-02-01', 1200.00, 1200.00, '2025-02-01', 'Online Portal', 'Paid'),
(2, '2025-03-01', 1200.00, 1200.00, '2025-03-01', 'Online Portal', 'Paid'),
(2, '2025-04-01', 1200.00, 1200.00, '2025-04-03', 'Online Portal', 'Paid'),
(2, '2025-05-01', 1200.00, 1200.00, '2025-05-01', 'Online Portal', 'Paid'),
(2, '2025-06-01', 1200.00, 1200.00, '2025-06-02', 'Online Portal', 'Paid'),
-- Lease 3 (2800) : late in March and April, partial in May, June unpaid
(3, '2025-01-01', 2800.00, 2800.00, '2025-01-05', 'Check', 'Paid'),
(3, '2025-02-01', 2800.00, 2800.00, '2025-02-05', 'Check', 'Paid'),
(3, '2025-03-01', 2800.00, 2800.00, '2025-03-12', 'Check', 'Paid'),
(3, '2025-04-01', 2800.00, 2800.00, '2025-04-09', 'Check', 'Paid'),
(3, '2025-05-01', 2800.00, 1500.00, '2025-05-06', 'Check', 'Partial'),
(3, '2025-06-01', 2800.00,    0.00, NULL,         NULL,    'Pending'),
-- Lease 4 (2200) : starts Feb, always on time
(4, '2025-02-01', 2200.00, 2200.00, '2025-02-01', 'Credit Card', 'Paid'),
(4, '2025-03-01', 2200.00, 2200.00, '2025-03-01', 'Credit Card', 'Paid'),
(4, '2025-04-01', 2200.00, 2200.00, '2025-04-01', 'Credit Card', 'Paid'),
(4, '2025-05-01', 2200.00, 2200.00, '2025-05-01', 'Credit Card', 'Paid'),
(4, '2025-06-01', 2200.00, 2200.00, '2025-06-01', 'Credit Card', 'Paid'),
-- Lease 5 (1900) : late in March, May and June unpaid
(5, '2025-01-01', 1900.00, 1900.00, '2025-01-01', 'Bank Transfer', 'Paid'),
(5, '2025-02-01', 1900.00, 1900.00, '2025-02-01', 'Bank Transfer', 'Paid'),
(5, '2025-03-01', 1900.00, 1900.00, '2025-03-15', 'Bank Transfer', 'Paid'),
(5, '2025-04-01', 1900.00, 1900.00, '2025-04-01', 'Bank Transfer', 'Paid'),
(5, '2025-05-01', 1900.00,    0.00, NULL,         NULL,            'Pending'),
(5, '2025-06-01', 1900.00,    0.00, NULL,         NULL,            'Pending'),
-- Lease 6 (1100) : one late payment in April
(6, '2025-01-01', 1100.00, 1100.00, '2025-01-01', 'Online Portal', 'Paid'),
(6, '2025-02-01', 1100.00, 1100.00, '2025-02-01', 'Online Portal', 'Paid'),
(6, '2025-03-01', 1100.00, 1100.00, '2025-03-01', 'Online Portal', 'Paid'),
(6, '2025-04-01', 1100.00, 1100.00, '2025-04-08', 'Online Portal', 'Paid'),
(6, '2025-05-01', 1100.00, 1100.00, '2025-05-01', 'Online Portal', 'Paid'),
(6, '2025-06-01', 1100.00, 1100.00, '2025-06-01', 'Online Portal', 'Paid'),
-- Lease 7 (2400) : starts Mar, always on time
(7, '2025-03-01', 2400.00, 2400.00, '2025-03-01', 'Bank Transfer', 'Paid'),
(7, '2025-04-01', 2400.00, 2400.00, '2025-04-01', 'Bank Transfer', 'Paid'),
(7, '2025-05-01', 2400.00, 2400.00, '2025-05-02', 'Bank Transfer', 'Paid'),
(7, '2025-06-01', 2400.00, 2400.00, '2025-06-01', 'Bank Transfer', 'Paid'),
-- Lease 8 (1650) : June partially paid
(8, '2025-01-01', 1650.00, 1650.00, '2025-01-03', 'Check', 'Paid'),
(8, '2025-02-01', 1650.00, 1650.00, '2025-02-03', 'Check', 'Paid'),
(8, '2025-03-01', 1650.00, 1650.00, '2025-03-03', 'Check', 'Paid'),
(8, '2025-04-01', 1650.00, 1650.00, '2025-04-03', 'Check', 'Paid'),
(8, '2025-05-01', 1650.00, 1650.00, '2025-05-03', 'Check', 'Paid'),
(8, '2025-06-01', 1650.00,  800.00, '2025-06-05', 'Check', 'Partial'),
-- Lease 9 (2300) : starts Apr, June unpaid
(9, '2025-04-01', 2300.00, 2300.00, '2025-04-01', 'Bank Transfer', 'Paid'),
(9, '2025-05-01', 2300.00, 2300.00, '2025-05-01', 'Bank Transfer', 'Paid'),
(9, '2025-06-01', 2300.00,    0.00, NULL,         NULL,            'Pending'),
-- Lease 11 (expired) : a little history from late 2024
(11, '2024-11-01', 1350.00, 1350.00, '2024-11-01', 'Credit Card', 'Paid'),
(11, '2024-12-01', 1350.00, 1350.00, '2024-12-02', 'Credit Card', 'Paid'),
-- Lease 12 (terminated early after February 2025)
(12, '2025-01-01', 1000.00, 1000.00, '2025-01-01', 'Cash', 'Paid'),
(12, '2025-02-01', 1000.00, 1000.00, '2025-02-04', 'Cash', 'Paid');

-- ---------------------------------------------------------------------
-- MAINTENANCE REQUESTS (14)
-- ---------------------------------------------------------------------
INSERT INTO maintenance_requests
(request_id, property_id, tenant_id, category, description, priority, status, reported_date, completed_date, cost, vendor_name) VALUES
(1,  1,  1,    'Plumbing',   'Kitchen sink leaking under cabinet',        'Medium',    'Completed',   '2025-01-14', '2025-01-16',  180.00, 'AquaFix Plumbing'),
(2,  4,  3,    'HVAC',       'Air conditioner not cooling',               'High',      'Completed',   '2025-03-20', '2025-03-22',  650.00, 'CoolAir Services'),
(3,  4,  3,    'Electrical', 'Garage outlet not working',                 'Low',       'Completed',   '2025-05-02', '2025-05-09',  120.00, 'BrightSpark Electric'),
(4,  6,  5,    'Appliance',  'Dishwasher not draining',                   'Medium',    'Completed',   '2025-02-10', '2025-02-15',  240.00, 'HomeAppliance Pros'),
(5,  6,  5,    'Plumbing',   'Water heater leaking',                      'Emergency', 'Completed',   '2025-04-18', '2025-04-18',  900.00, 'AquaFix Plumbing'),
(6,  8,  6,    'Electrical', 'Flickering lights in main room',            'Low',       'In Progress', '2025-06-10', NULL,            0.00, 'BrightSpark Electric'),
(7,  10, 7,    'HVAC',       'Heater making loud noise',                  'Medium',    'Open',        '2025-06-20', NULL,            0.00, NULL),
(8,  11, 8,    'Structural', 'Roof leak in bedroom ceiling',              'High',      'In Progress', '2025-06-15', NULL,          350.00, 'TopShield Roofing'),
(9,  7,  NULL, 'Structural', 'Water damage repair in bathroom (vacant unit)','High',   'In Progress', '2025-05-25', NULL,         2200.00, 'RestoreRight Contractors'),
(10, 12, 9,    'Appliance',  'Washing machine malfunction',               'Low',       'Completed',   '2025-05-12', '2025-05-20',  310.00, 'HomeAppliance Pros'),
(11, 2,  2,    'Plumbing',   'Clogged bathroom drain',                    'Low',       'Completed',   '2025-03-08', '2025-03-09',   95.00, 'AquaFix Plumbing'),
(12, 5,  4,    'Electrical', 'Circuit breaker trips repeatedly',          'High',      'Completed',   '2025-04-02', '2025-04-04',  420.00, 'BrightSpark Electric'),
(13, 1,  1,    'HVAC',       'Thermostat unresponsive (resolved by tenant)','Low',     'Cancelled',   '2025-04-25', NULL,            0.00, NULL),
(14, 3,  NULL, 'Other',      'Repaint and deep clean before re-listing',  'Medium',    'Completed',   '2024-09-10', '2024-09-20',  800.00, 'FreshCoat Painters');
