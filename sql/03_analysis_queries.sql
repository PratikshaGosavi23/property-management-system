-- =====================================================================
-- File    : 03_analysis_queries.sql
-- Purpose : Core SQL techniques on the property management database
--           (joins, subqueries, aggregation, WHERE/HAVING, CASE)
-- Run     : after 01_schema.sql and 02_sample_data.sql
-- =====================================================================
USE property_mgmt;

-- "Today" is fixed so results are repeatable with the sample data.
SET @report_date = '2025-06-30';


-- #####################################################################
-- SECTION A : JOINS
-- #####################################################################

-- A1. INNER JOIN (4 tables)
--     Who lives where, who owns it, and what they pay.
SELECT  l.lease_id,
        p.property_name,
        CONCAT(t.first_name, ' ', t.last_name) AS tenant,
        CONCAT(o.first_name, ' ', o.last_name) AS owner,
        l.monthly_rent,
        l.end_date
FROM    leases      l
JOIN    properties  p ON p.property_id = l.property_id
JOIN    tenants     t ON t.tenant_id   = l.tenant_id
JOIN    owners      o ON o.owner_id    = p.owner_id
WHERE   l.status = 'Active'
ORDER BY p.property_name;


-- A2. LEFT JOIN
--     Properties that currently have NO active lease (vacancies).
--     The status filter sits in the ON clause so properties with only
--     old leases are still kept by the LEFT JOIN.
SELECT  p.property_id,
        p.property_name,
        p.status        AS property_status,
        p.listed_rent
FROM    properties p
LEFT JOIN leases   l ON l.property_id = p.property_id
                    AND l.status = 'Active'
WHERE   l.lease_id IS NULL
ORDER BY p.property_id;


-- A3. LEFT JOIN
--     Tenants who have never signed a lease (rental applicants).
SELECT  t.tenant_id,
        CONCAT(t.first_name, ' ', t.last_name) AS tenant,
        t.email
FROM    tenants t
LEFT JOIN leases l ON l.tenant_id = t.tenant_id
WHERE   l.lease_id IS NULL;


-- A4. LEFT JOIN on an optional relationship
--     Maintenance requests with the tenant name. Requests raised by
--     management on vacant units have no tenant, so INNER JOIN would
--     silently drop them.
SELECT  m.request_id,
        p.property_name,
        COALESCE(CONCAT(t.first_name, ' ', t.last_name), 'Management') AS raised_by,
        m.category,
        m.priority,
        m.status,
        m.cost
FROM    maintenance_requests m
JOIN    properties p ON p.property_id = m.property_id
LEFT JOIN tenants  t ON t.tenant_id   = m.tenant_id
ORDER BY m.reported_date DESC;


-- #####################################################################
-- SECTION B : SUBQUERIES
-- #####################################################################

-- B1. Scalar subquery in WHERE
--     Properties listed above the portfolio's average rent.
SELECT  property_name, property_type, listed_rent
FROM    properties
WHERE   listed_rent > (SELECT AVG(listed_rent) FROM properties)
ORDER BY listed_rent DESC;


-- B2. IN subquery
--     Properties that have had at least one High/Emergency repair.
SELECT  property_id, property_name, city
FROM    properties
WHERE   property_id IN (SELECT property_id
                        FROM   maintenance_requests
                        WHERE  priority IN ('High', 'Emergency'))
ORDER BY property_name;


-- B3. NOT EXISTS (correlated subquery)
--     Active leases that have received no money at all in 2025.
SELECT  l.lease_id, l.property_id, l.tenant_id
FROM    leases l
WHERE   l.status = 'Active'
  AND   NOT EXISTS (SELECT 1
                    FROM   payments pay
                    WHERE  pay.lease_id = l.lease_id
                      AND  pay.amount_paid > 0);
-- (Returns no rows with the sample data: every active lease has paid something.)


-- B4. Correlated subquery
--     For each active lease, the date of its most recent payment.
SELECT  l.lease_id,
        p.property_name,
        (SELECT MAX(pay.payment_date)
         FROM   payments pay
         WHERE  pay.lease_id = l.lease_id) AS last_payment_date
FROM    leases l
JOIN    properties p ON p.property_id = l.property_id
WHERE   l.status = 'Active'
ORDER BY last_payment_date;


-- B5. Subquery in FROM (derived table)
--     Owners whose total repair spend is above the average owner's spend.
SELECT  o.owner_id,
        CONCAT(o.first_name, ' ', o.last_name) AS owner,
        s.total_repair_cost
FROM    owners o
JOIN   (SELECT p.owner_id, SUM(m.cost) AS total_repair_cost
        FROM   maintenance_requests m
        JOIN   properties p ON p.property_id = m.property_id
        GROUP BY p.owner_id) s ON s.owner_id = o.owner_id
WHERE   s.total_repair_cost > (SELECT AVG(x.total_cost)
                               FROM  (SELECT SUM(m2.cost) AS total_cost
                                      FROM   maintenance_requests m2
                                      JOIN   properties p2 ON p2.property_id = m2.property_id
                                      GROUP BY p2.owner_id) x)
ORDER BY s.total_repair_cost DESC;


-- #####################################################################
-- SECTION C : AGGREGATION, GROUP BY, HAVING
-- #####################################################################

-- C1. Portfolio overview by city and property type
SELECT  city,
        property_type,
        COUNT(*)                     AS properties,
        ROUND(AVG(listed_rent), 2)   AS avg_listed_rent,
        MIN(listed_rent)             AS min_rent,
        MAX(listed_rent)             AS max_rent
FROM    properties
GROUP BY city, property_type
ORDER BY city, property_type;


-- C2. Rent collected per owner (JOIN + GROUP BY + SUM)
SELECT  o.owner_id,
        CONCAT(o.first_name, ' ', o.last_name) AS owner,
        COUNT(DISTINCT p.property_id)          AS properties,
        SUM(pay.amount_paid)                   AS rent_collected
FROM    owners o
JOIN    properties p   ON p.owner_id    = o.owner_id
JOIN    leases l       ON l.property_id = p.property_id
JOIN    payments pay   ON pay.lease_id  = l.lease_id
GROUP BY o.owner_id, o.first_name, o.last_name
ORDER BY rent_collected DESC;


-- C3. HAVING: maintenance categories where total spend exceeds $500
SELECT  category,
        COUNT(*)  AS requests,
        SUM(cost) AS total_cost,
        ROUND(AVG(cost), 2) AS avg_cost
FROM    maintenance_requests
WHERE   status <> 'Cancelled'
GROUP BY category
HAVING  SUM(cost) > 500
ORDER BY total_cost DESC;


-- C4. WHERE + GROUP BY + HAVING
--     Tenants who paid rent more than 5 days after the due date
--     at least twice (grace period = 5 days).
SELECT  t.tenant_id,
        CONCAT(t.first_name, ' ', t.last_name) AS tenant,
        COUNT(*)                               AS late_payments
FROM    payments pay
JOIN    leases l   ON l.lease_id  = pay.lease_id
JOIN    tenants t  ON t.tenant_id = l.tenant_id
WHERE   pay.payment_date > DATE_ADD(pay.due_date, INTERVAL 5 DAY)
GROUP BY t.tenant_id, t.first_name, t.last_name
HAVING  COUNT(*) >= 2;


-- #####################################################################
-- SECTION D : CASE STATEMENTS
-- #####################################################################

-- D1. Classify every payment (on time / late / partial / overdue / unpaid)
SELECT  pay.payment_id,
        pay.lease_id,
        pay.due_date,
        pay.amount_due,
        pay.amount_paid,
        CASE
            WHEN pay.payment_status = 'Paid'
                 AND pay.payment_date <= DATE_ADD(pay.due_date, INTERVAL 5 DAY) THEN 'On Time'
            WHEN pay.payment_status = 'Paid'                                    THEN 'Paid Late'
            WHEN pay.payment_status = 'Partial'                                 THEN 'Partially Paid'
            WHEN pay.payment_status = 'Pending' AND pay.due_date < @report_date THEN 'Overdue'
            ELSE 'Not Yet Due'
        END AS payment_label
FROM    payments pay
WHERE   pay.due_date >= '2025-04-01'
ORDER BY pay.due_date, pay.lease_id;


-- D2. Count payments per label with CASE inside an aggregate
--     (a pivot-style summary in a single row)
SELECT  SUM(CASE WHEN payment_status = 'Paid'
                  AND payment_date <= DATE_ADD(due_date, INTERVAL 5 DAY) THEN 1 ELSE 0 END) AS on_time,
        SUM(CASE WHEN payment_status = 'Paid'
                  AND payment_date >  DATE_ADD(due_date, INTERVAL 5 DAY) THEN 1 ELSE 0 END) AS paid_late,
        SUM(CASE WHEN payment_status = 'Partial' THEN 1 ELSE 0 END)                           AS partial,
        SUM(CASE WHEN payment_status = 'Pending' THEN 1 ELSE 0 END)                           AS unpaid
FROM    payments
WHERE   due_date BETWEEN '2025-01-01' AND @report_date;


-- D3. Segment properties into rent tiers
SELECT  property_name,
        listed_rent,
        CASE
            WHEN listed_rent >= 2200 THEN 'Premium'
            WHEN listed_rent >= 1400 THEN 'Mid-range'
            ELSE 'Budget'
        END AS rent_tier
FROM    properties
ORDER BY listed_rent DESC;
