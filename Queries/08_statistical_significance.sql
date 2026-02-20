USE saas_analytics;

WITH stats AS (
  SELECT
    test_group,
    COUNT(*) AS n,
    SUM(conversion) AS x,
    SUM(conversion) / COUNT(*) AS p
  FROM pricing_experiments
  GROUP BY test_group
),
pooled AS (
  SELECT
    SUM(x) / SUM(n) AS p_pool
  FROM stats
)

SELECT
  A.n AS n_A,
  A.x AS conv_A,
  ROUND(100*A.p,2) AS cr_A_pct,

  B.n AS n_B,
  B.x AS conv_B,
  ROUND(100*B.p,2) AS cr_B_pct,

  ROUND(100*(B.p - A.p),2) AS diff_pp,
  ROUND(100*(B.p/A.p - 1),2) AS relative_lift_pct,

  ROUND(
    (B.p - A.p) /
    SQRT(pooled.p_pool * (1 - pooled.p_pool) * (1/A.n + 1/B.n)),
  4) AS z_score

FROM stats A
JOIN stats B
JOIN pooled
WHERE A.test_group = 'A'
  AND B.test_group = 'B';