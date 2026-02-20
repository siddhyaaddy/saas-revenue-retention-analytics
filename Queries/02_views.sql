/* =============================================================================
   01_views.sql
   SaaS Analytics — Reusable Views for KPIs, Churn, Cohorts, Revenue

   Run AFTER: 00_schema_and_seed.sql
============================================================================= */

USE saas_analytics;


-- 1) Monthly KPIs View
--    month, mrr, paid_subscriptions, arpu, failed_payments, total_payments, fail_rate_pct

DROP VIEW IF EXISTS vw_monthly_kpis;

CREATE VIEW vw_monthly_kpis AS
SELECT
  m.month,
  m.mrr,
  m.paid_subscriptions,
  ROUND(m.mrr / NULLIF(m.paid_subscriptions, 0), 2) AS arpu,
  f.failed_payments,
  f.total_payments,
  ROUND(100 * f.failed_payments / NULLIF(f.total_payments, 0), 2) AS fail_rate_pct
FROM
(
  SELECT
    DATE_FORMAT(payment_date, '%Y-%m-01') AS month,
    ROUND(SUM(CASE WHEN payment_status='success' THEN amount ELSE 0 END), 2) AS mrr,
    COUNT(DISTINCT CASE WHEN payment_status='success' THEN subscription_id END) AS paid_subscriptions
  FROM payments
  GROUP BY DATE_FORMAT(payment_date, '%Y-%m-01')
) m
JOIN
(
  SELECT
    DATE_FORMAT(payment_date, '%Y-%m-01') AS month,
    SUM(CASE WHEN payment_status='failed' THEN 1 ELSE 0 END) AS failed_payments,
    COUNT(*) AS total_payments
  FROM payments
  GROUP BY DATE_FORMAT(payment_date, '%Y-%m-01')
) f
ON m.month = f.month;


-- 2) Monthly Churn (count of churned subscriptions by churn month)

DROP VIEW IF EXISTS vw_monthly_churn;

CREATE VIEW vw_monthly_churn AS
SELECT
  DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
  COUNT(*) AS churned_subscriptions
FROM subscriptions
WHERE subscription_status = 'churned'
  AND end_date IS NOT NULL
GROUP BY 1;


-- 3) Revenue by Plan Tier (Monthly)

DROP VIEW IF EXISTS vw_revenue_by_plan_month;

CREATE VIEW vw_revenue_by_plan_month AS
SELECT
  DATE_FORMAT(p.payment_date, '%Y-%m-01') AS month,
  s.plan_tier,
  ROUND(SUM(CASE WHEN p.payment_status='success' THEN p.amount ELSE 0 END), 2) AS revenue
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.subscription_id
GROUP BY 1,2;


-- 4) Cohort Retention (paid activity by signup cohort)

DROP VIEW IF EXISTS vw_cohort_retention;

CREATE VIEW vw_cohort_retention AS
SELECT
  DATE_FORMAT(u.signup_date, '%Y-%m-01') AS cohort_month,
  DATE_FORMAT(p.payment_date, '%Y-%m-01') AS activity_month,
  TIMESTAMPDIFF(
    MONTH,
    DATE_FORMAT(u.signup_date, '%Y-%m-01'),
    DATE_FORMAT(p.payment_date, '%Y-%m-01')
  ) AS month_number,
  COUNT(DISTINCT u.user_id) AS active_users
FROM users u
JOIN subscriptions s ON s.user_id = u.user_id
JOIN payments p ON p.subscription_id = s.subscription_id
WHERE p.payment_status = 'success'
GROUP BY 1,2,3;


-- 5) Sanity Checks

SHOW FULL TABLES FROM saas_analytics WHERE Table_type = 'VIEW';

SELECT * FROM vw_monthly_kpis ORDER BY month;
SELECT * FROM vw_monthly_churn ORDER BY churn_month;
SELECT * FROM vw_revenue_by_plan_month ORDER BY month, plan_tier;
SELECT * FROM vw_cohort_retention ORDER BY cohort_month, month_number;