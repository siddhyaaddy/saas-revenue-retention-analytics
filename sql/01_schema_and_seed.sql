/* =============================================================================
   00_schema_and_seed.sql
   SaaS Analytics — Schema + Synthetic Data Generator

   DB: MySQL / MariaDB (DBeaver compatible)

   What this script does:
   1) Creates database + tables (users, subscriptions, payments, events, experiments)
   2) Builds a helper numbers table (1..10000) used for synthetic generation
   3) Truncates existing data safely (re-runnable)
   4) Generates:
      - 10,000 users
      - 1 subscription per user
      - monthly payments per subscription duration

   WARNING:
   - This script TRUNCATES data (wipes rows) every time you run it.
============================================================================= */


-- 0) DATABASE

CREATE DATABASE IF NOT EXISTS saas_analytics;
USE saas_analytics;

SELECT DATABASE() AS current_db;


-- 1) TABLES (SCHEMA)


-- USERS: one row per user
CREATE TABLE IF NOT EXISTS users (
  user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  signup_date DATE NOT NULL,
  country VARCHAR(50),
  device_type VARCHAR(20),
  acquisition_channel VARCHAR(50)
);

-- SUBSCRIPTIONS: one subscription per user (in our generator)
CREATE TABLE IF NOT EXISTS subscriptions (
  subscription_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  plan_tier ENUM('Basic','Pro','Enterprise') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  subscription_status ENUM('active','churned','paused') NOT NULL,
  monthly_price DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_subscriptions_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- PAYMENTS: one row per monthly billing attempt
CREATE TABLE IF NOT EXISTS payments (
  payment_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  subscription_id BIGINT NOT NULL,
  payment_date DATE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_status ENUM('success','failed') NOT NULL,
  payment_method ENUM('card','bank_transfer','paypal') NOT NULL,
  CONSTRAINT fk_payments_subscriptions
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
);

-- PRODUCT EVENTS (optional, for product usage analytics later)
CREATE TABLE IF NOT EXISTS product_events (
  event_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  event_type ENUM('login','feature_used','export','api_call','support_ticket') NOT NULL,
  event_date DATE NOT NULL,
  session_id VARCHAR(64),
  CONSTRAINT fk_events_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- PRICING EXPERIMENTS (A/B testing)
CREATE TABLE IF NOT EXISTS pricing_experiments (
  experiment_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  experiment_name VARCHAR(100),
  test_group ENUM('A','B'),
  price_variant VARCHAR(50),
  conversion TINYINT,        -- 1 = converted, 0 = not converted
  assigned_date DATE,
  CONSTRAINT fk_experiments_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

SHOW TABLES;


-- 2) HELPER TABLE: numbers (1..10000)
--    Used to generate synthetic users and monthly payment rows.
CREATE TABLE IF NOT EXISTS numbers (n INT PRIMARY KEY);

TRUNCATE TABLE numbers;

INSERT INTO numbers (n)
SELECT a.N + b.N*10 + c.N*100 + d.N*1000 + 1 AS num
FROM
 (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
 (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
 (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c,
 (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d;

SELECT COUNT(*) AS numbers_cnt FROM numbers;


-- 3) RESET (re-run safe)

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE pricing_experiments;
TRUNCATE TABLE product_events;
TRUNCATE TABLE payments;
TRUNCATE TABLE subscriptions;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;


-- 4) GENERATE USERS (10,000)

INSERT INTO users (signup_date, country, device_type, acquisition_channel)
SELECT
  DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND(n)*365) DAY) AS signup_date,

  -- Country distribution
  CASE
    WHEN RAND(n) < 0.60 THEN 'US'
    WHEN RAND(n) < 0.70 THEN 'CA'
    WHEN RAND(n) < 0.80 THEN 'UK'
    WHEN RAND(n) < 0.90 THEN 'IN'
    WHEN RAND(n) < 0.95 THEN 'DE'
    ELSE 'AU'
  END AS country,

  -- Device distribution
  CASE
    WHEN RAND(n) < 0.55 THEN 'web'
    WHEN RAND(n) < 0.80 THEN 'ios'
    ELSE 'android'
  END AS device_type,

  -- Acquisition channel distribution
  CASE
    WHEN RAND(n) < 0.45 THEN 'organic'
    WHEN RAND(n) < 0.75 THEN 'paid_search'
    WHEN RAND(n) < 0.87 THEN 'linkedin'
    WHEN RAND(n) < 0.95 THEN 'referral'
    ELSE 'partner'
  END AS acquisition_channel
FROM numbers;

SELECT COUNT(*) AS users_cnt FROM users;


-- 5) GENERATE SUBSCRIPTIONS (1 per user)

INSERT INTO subscriptions (user_id, plan_tier, start_date, end_date, subscription_status, monthly_price)
SELECT
  u.user_id,

  -- Plan tier distribution
  CASE
    WHEN RAND(u.user_id) < 0.70 THEN 'Basic'
    WHEN RAND(u.user_id) < 0.95 THEN 'Pro'
    ELSE 'Enterprise'
  END AS plan_tier,

  -- Start date within 0..14 days after signup
  DATE_ADD(u.signup_date, INTERVAL FLOOR(RAND(u.user_id)*14) DAY) AS start_date,

  -- End date set later for churned/paused
  NULL AS end_date,

  -- Status distribution
  CASE
    WHEN RAND(u.user_id) < 0.75 THEN 'active'
    WHEN RAND(u.user_id) < 0.95 THEN 'churned'
    ELSE 'paused'
  END AS subscription_status,

  -- Monthly price (simple mapping)
  CASE
    WHEN RAND(u.user_id) < 0.70 THEN 19.99
    WHEN RAND(u.user_id) < 0.95 THEN 49.99
    ELSE 199.99
  END AS monthly_price
FROM users u;

-- Set end_date for churned/paused subscriptions
UPDATE subscriptions
SET end_date =
  CASE
    WHEN subscription_status IN ('churned','paused')
      THEN DATE_ADD(start_date, INTERVAL (30 + FLOOR(RAND(subscription_id)*240)) DAY)
    ELSE NULL
  END;

-- Subscription sanity checks
SELECT COUNT(*) AS subs_cnt FROM subscriptions;

SELECT subscription_status, COUNT(*) AS cnt
FROM subscriptions
GROUP BY subscription_status;

SELECT plan_tier, COUNT(*) AS cnt
FROM subscriptions
GROUP BY plan_tier;


-- 6) GENERATE PAYMENTS (monthly attempts)

TRUNCATE TABLE payments;

INSERT INTO payments (subscription_id, payment_date, amount, payment_status, payment_method)
SELECT
  s.subscription_id,
  DATE_ADD(s.start_date, INTERVAL n.n MONTH) AS payment_date,
  s.monthly_price AS amount,

  -- 92% success rate
  CASE
    WHEN RAND(s.subscription_id + n.n) < 0.92 THEN 'success'
    ELSE 'failed'
  END AS payment_status,

  -- Payment method distribution
  CASE
    WHEN RAND(s.subscription_id) < 0.70 THEN 'card'
    WHEN RAND(s.subscription_id) < 0.90 THEN 'bank_transfer'
    ELSE 'paypal'
  END AS payment_method
FROM subscriptions s
JOIN numbers n
  ON n.n <= TIMESTAMPDIFF(
       MONTH,
       s.start_date,
       COALESCE(s.end_date, CURDATE())
     );

SELECT COUNT(*) AS payments_cnt FROM payments;


-- 7) QUICK CHECKS (optional)

SELECT VERSION() AS db_version;