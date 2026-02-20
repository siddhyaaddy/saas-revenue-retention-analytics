USE saas_analytics;

-- Monthly churn counts
DROP VIEW IF EXISTS vw_monthly_churn;

CREATE VIEW vw_monthly_churn AS
SELECT
  DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
  COUNT(*) AS churned_subscriptions
FROM subscriptions
WHERE subscription_status = 'churned'
  AND end_date IS NOT NULL
GROUP BY 1;

-- Churn rate % (using paid subscriptions as the base)
DROP VIEW IF EXISTS vw_monthly_churn_rate;

CREATE VIEW vw_monthly_churn_rate AS
SELECT
  k.month,
  COALESCE(c.churned_subscriptions, 0) AS churned_subscriptions,
  k.paid_subscriptions,
  ROUND(100 * COALESCE(c.churned_subscriptions, 0) / NULLIF(k.paid_subscriptions, 0), 2) AS churn_rate_pct
FROM vw_monthly_kpis k
LEFT JOIN vw_monthly_churn c
  ON c.churn_month = k.month;

-- Quick checks
SELECT * FROM vw_monthly_churn ORDER BY churn_month;
SELECT * FROM vw_monthly_churn_rate ORDER BY month;