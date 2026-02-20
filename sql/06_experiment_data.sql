USE saas_analytics;

INSERT INTO pricing_experiments (
    user_id,
    experiment_name,
    test_group,
    price_variant,
    conversion,
    assigned_date
)
SELECT
    u.user_id,
    'pricing_test_v1' AS experiment_name,

    -- deterministic group assignment
    CASE
        WHEN u.user_id % 2 = 0 THEN 'A'
        ELSE 'B'
    END AS test_group,

    CASE
        WHEN u.user_id % 2 = 0 THEN 'Old_Price'
        ELSE 'New_Price'
    END AS price_variant,

    CASE
        -- A = 30% conversion
        WHEN u.user_id % 2 = 0 AND RAND() < 0.30 THEN 1

        -- B = 35% conversion
        WHEN u.user_id % 2 = 1 AND RAND() < 0.35 THEN 1

        ELSE 0
    END AS conversion,

    CURDATE()

FROM users u;


TRUNCATE TABLE pricing_experiments;