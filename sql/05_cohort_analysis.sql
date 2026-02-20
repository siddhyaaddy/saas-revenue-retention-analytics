USE saas_analytics;

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

-- Quick check
SELECT *
FROM vw_cohort_retention
ORDER BY cohort_month, month_number;