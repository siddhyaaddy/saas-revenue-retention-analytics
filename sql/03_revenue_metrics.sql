USE saas_analytics;

-- Monthly KPIs: MRR, paid subs, ARPU, failed payment rate
DROP VIEW IF EXISTS vw_monthly_kpis;

CREATE VIEW vw_monthly_kpis AS
SELECT
  m.month,
  m.mrr,
  m.paid_subscriptions,
  ROUND(m.mrr / NULLIF(m.paid_subscriptions, 0), 2) AS arpu,
  f.failed_payments,
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

-- Revenue by plan tier (monthly)
DROP VIEW IF EXISTS vw_revenue_by_plan_month;

CREATE VIEW vw_revenue_by_plan_month AS
SELECT
  DATE_FORMAT(p.payment_date, '%Y-%m-01') AS month,
  s.plan_tier,
  ROUND(SUM(CASE WHEN p.payment_status='success' THEN p.amount ELSE 0 END), 2) AS revenue
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.subscription_id
GROUP BY 1,2;

-- Revenue by plan tier (total)
DROP VIEW IF EXISTS vw_revenue_by_plan_total;

CREATE VIEW vw_revenue_by_plan_total AS
SELECT
  s.plan_tier,
  ROUND(SUM(CASE WHEN p.payment_status='success' THEN p.amount ELSE 0 END), 2) AS total_revenue
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.subscription_id
GROUP BY 1
ORDER BY total_revenue DESC;

-- Quick checks
SELECT * FROM vw_monthly_kpis ORDER BY month;
SELECT * FROM vw_revenue_by_plan_month ORDER BY month, plan_tier;
SELECT * FROM vw_revenue_by_plan_total ORDER BY total_revenue DESC;