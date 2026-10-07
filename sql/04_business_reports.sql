-- =====================================================================
-- File    : 04_business_reports.sql
-- Purpose : Business reports a property manager would run every month
-- Run     : after 03_analysis_queries.sql (before 05_transactions.sql)
-- Reports : 1 Monthly rent collection      4 Occupancy by city
--           2 Overdue rent (aging)         5 Leases expiring soon
--           3 Owner financial statement    6 Maintenance performance
-- =====================================================================
USE property_mgmt;

SET @report_date = '2025-06-30';
SET @year_start  = '2025-01-01';

-- ---------------------------------------------------------------------
-- Reusable view: one row per lease with all the descriptive details.
-- Reports 2 and 5 build on it instead of repeating the same 4-table join.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_lease_details AS
SELECT  l.lease_id,
        l.status        AS lease_status,
        p.property_id,
        p.property_name,
        p.city,
        o.owner_id,
        CONCAT(o.first_name, ' ', o.last_name) AS owner_name,
        t.tenant_id,
        CONCAT(t.first_name, ' ', t.last_name) AS tenant_name,
        t.email         AS tenant_email,
        l.start_date,
        l.end_date,
        l.monthly_rent
FROM    leases l
JOIN    properties p ON p.property_id = l.property_id
JOIN    owners     o ON o.owner_id    = p.owner_id
JOIN    tenants    t ON t.tenant_id   = l.tenant_id;


-- =====================================================================
-- REPORT 1 : Monthly rent collection
-- Question : How much rent did we bill vs. actually collect each month?
-- =====================================================================
SELECT  DATE_FORMAT(due_date, '%Y-%m')            AS rent_month,
        COUNT(*)                                  AS invoices,
        SUM(amount_due)                           AS billed,
        SUM(amount_paid)                          AS collected,
        SUM(amount_due - amount_paid)             AS outstanding,
        ROUND(100 * SUM(amount_paid) / SUM(amount_due), 1) AS collection_rate_pct
FROM    payments
WHERE   due_date BETWEEN @year_start AND @report_date
GROUP BY DATE_FORMAT(due_date, '%Y-%m')
ORDER BY rent_month;


-- =====================================================================
-- REPORT 2 : Overdue rent with aging buckets
-- Question : Who owes us money, how much, and for how long?
-- =====================================================================
-- 2a. Detail by invoice
SELECT  v.tenant_name,
        v.property_name,
        pay.due_date,
        (pay.amount_due - pay.amount_paid)       AS balance_owed,
        DATEDIFF(@report_date, pay.due_date)     AS days_overdue,
        CASE
            WHEN DATEDIFF(@report_date, pay.due_date) <= 30 THEN '0-30 days'
            WHEN DATEDIFF(@report_date, pay.due_date) <= 60 THEN '31-60 days'
            ELSE '60+ days'
        END                                      AS aging_bucket
FROM    payments pay
JOIN    vw_lease_details v ON v.lease_id = pay.lease_id
WHERE   pay.payment_status <> 'Paid'
  AND   pay.due_date < @report_date
  AND   v.lease_status = 'Active'
ORDER BY days_overdue DESC;

-- 2b. Summary by tenant (anyone owing more than $1,000 is flagged)
SELECT  v.tenant_name,
        v.tenant_email,
        COUNT(*)                                 AS unpaid_invoices,
        SUM(pay.amount_due - pay.amount_paid)    AS total_owed
FROM    payments pay
JOIN    vw_lease_details v ON v.lease_id = pay.lease_id
WHERE   pay.payment_status <> 'Paid'
  AND   pay.due_date < @report_date
  AND   v.lease_status = 'Active'
GROUP BY v.tenant_id, v.tenant_name, v.tenant_email
HAVING  SUM(pay.amount_due - pay.amount_paid) > 1000
ORDER BY total_owed DESC;


-- =====================================================================
-- REPORT 3 : Owner financial statement (year to date)
-- Question : For each owner, how much rent came in, how much was spent
--            on repairs, and what is the net income?
-- Note     : Each measure is aggregated in its own CTE first. Joining
--            payments and maintenance directly would multiply rows and
--            inflate the totals (the "fan-out" problem).
-- =====================================================================
WITH rent AS (
    SELECT  p.owner_id, SUM(pay.amount_paid) AS rent_collected
    FROM    payments pay
    JOIN    leases l      ON l.lease_id    = pay.lease_id
    JOIN    properties p  ON p.property_id = l.property_id
    WHERE   pay.due_date BETWEEN @year_start AND @report_date
    GROUP BY p.owner_id
),
repairs AS (
    SELECT  p.owner_id, SUM(m.cost) AS repair_cost
    FROM    maintenance_requests m
    JOIN    properties p ON p.property_id = m.property_id
    WHERE   m.reported_date BETWEEN @year_start AND @report_date
      AND   m.status <> 'Cancelled'
    GROUP BY p.owner_id
),
portfolio AS (
    SELECT  owner_id,
            COUNT(*)                                   AS properties,
            SUM(CASE WHEN status = 'Occupied' THEN 1 ELSE 0 END) AS occupied
    FROM    properties
    GROUP BY owner_id
)
SELECT  CONCAT(o.first_name, ' ', o.last_name)         AS owner,
        pf.properties,
        pf.occupied,
        COALESCE(r.rent_collected, 0)                  AS rent_collected,
        COALESCE(rp.repair_cost, 0)                    AS repair_cost,
        COALESCE(r.rent_collected, 0)
          - COALESCE(rp.repair_cost, 0)                AS net_income,
        ROUND(100 * COALESCE(rp.repair_cost, 0)
              / NULLIF(r.rent_collected, 0), 1)        AS repair_pct_of_rent
FROM    owners o
JOIN    portfolio pf     ON pf.owner_id = o.owner_id
LEFT JOIN rent r         ON r.owner_id  = o.owner_id
LEFT JOIN repairs rp     ON rp.owner_id = o.owner_id
ORDER BY net_income DESC;


-- =====================================================================
-- REPORT 4 : Occupancy by city
-- Question : Where are our vacancies, and what rent are we missing?
-- =====================================================================
SELECT  city,
        COUNT(*)                                                         AS total_units,
        SUM(CASE WHEN status = 'Occupied' THEN 1 ELSE 0 END)             AS occupied,
        SUM(CASE WHEN status <> 'Occupied' THEN 1 ELSE 0 END)            AS vacant,
        ROUND(100 * SUM(CASE WHEN status = 'Occupied' THEN 1 ELSE 0 END)
              / COUNT(*), 1)                                             AS occupancy_pct,
        SUM(CASE WHEN status <> 'Occupied' THEN listed_rent ELSE 0 END)  AS monthly_rent_lost_to_vacancy
FROM    properties
GROUP BY city
ORDER BY occupancy_pct DESC;


-- =====================================================================
-- REPORT 5 : Leases expiring in the next 90 days (renewal pipeline)
-- Question : Which leases do we need to renew or re-let soon?
-- =====================================================================
SELECT  v.property_name,
        v.tenant_name,
        v.owner_name,
        v.monthly_rent,
        v.end_date,
        DATEDIFF(v.end_date, @report_date) AS days_left,
        CASE
            WHEN DATEDIFF(v.end_date, @report_date) <= 30 THEN 'URGENT - contact tenant now'
            WHEN DATEDIFF(v.end_date, @report_date) <= 60 THEN 'Send renewal offer'
            ELSE 'Monitor'
        END                                AS recommended_action
FROM    vw_lease_details v
WHERE   v.lease_status = 'Active'
  AND   v.end_date BETWEEN @report_date AND DATE_ADD(@report_date, INTERVAL 90 DAY)
ORDER BY v.end_date;


-- =====================================================================
-- REPORT 6 : Maintenance performance
-- Question : Which problems cost the most and how quickly do we fix them?
-- =====================================================================
-- 6a. By category (completed jobs only)
SELECT  category,
        COUNT(*)                                        AS jobs_completed,
        ROUND(AVG(DATEDIFF(completed_date, reported_date)), 1) AS avg_days_to_fix,
        SUM(cost)                                       AS total_cost,
        ROUND(AVG(cost), 2)                             AS avg_cost
FROM    maintenance_requests
WHERE   status = 'Completed'
GROUP BY category
ORDER BY total_cost DESC;

-- 6b. Open backlog, oldest and most urgent first
SELECT  m.request_id,
        p.property_name,
        m.category,
        m.priority,
        m.status,
        DATEDIFF(@report_date, m.reported_date) AS days_open,
        CASE WHEN m.priority IN ('High', 'Emergency')
              AND DATEDIFF(@report_date, m.reported_date) > 14
             THEN 'ESCALATE' ELSE 'On track' END AS flag
FROM    maintenance_requests m
JOIN    properties p ON p.property_id = m.property_id
WHERE   m.status IN ('Open', 'In Progress')
ORDER BY FIELD(m.priority, 'Emergency', 'High', 'Medium', 'Low'), days_open DESC;
