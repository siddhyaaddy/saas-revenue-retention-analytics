USE saas_analytics;

SELECT
  test_group,
  COUNT(*) AS users,
  SUM(conversion) AS conversions,
  ROUND(100 * SUM(conversion) / COUNT(*), 2) AS conversion_rate_pct
FROM pricing_experiments
GROUP BY test_group;


SELECT
    test_group,
    SUM(conversion * monthly_price) AS experiment_revenue
FROM pricing_experiments pe
JOIN subscriptions s 
    ON pe.user_id = s.user_id
GROUP BY test_group;