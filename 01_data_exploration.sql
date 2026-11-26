-- Credit Card Fraud Detection & Transaction Risk Analytics
-- 01: Data exploration and fraud overview
-- Database: fraud_analytics_project | MySQL 8+

USE fraud_analytics_project;

-- Dataset size and fraud distribution
SELECT
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS fraud_transactions,
    COUNT(CASE WHEN is_fraud = 0 THEN 1 END) AS genuine_transactions,
    ROUND(COUNT(CASE WHEN is_fraud = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2) AS fraud_transaction_value,
    ROUND(AVG(CASE WHEN is_fraud = 1 THEN amount END), 2) AS avg_fraud_amount,
    ROUND(AVG(CASE WHEN is_fraud = 0 THEN amount END), 2) AS avg_genuine_amount
FROM transactions;

-- Fraud transaction value as a proportion of all transaction value
SELECT
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2) AS fraud_value,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END) * 100.0 / SUM(amount), 2)
        AS fraud_value_share_pct
FROM transactions;

-- Fraud by merchant category
SELECT
    merchant_category,
    COUNT(*) AS transactions,
    COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS fraud_transactions,
    ROUND(COUNT(CASE WHEN is_fraud = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2) AS fraud_value
FROM transactions
GROUP BY merchant_category
ORDER BY fraud_transactions DESC, fraud_value DESC;

-- Fraud by channel / transaction type
SELECT
    transaction_type,
    COUNT(*) AS transactions,
    COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS fraud_transactions,
    ROUND(COUNT(CASE WHEN is_fraud = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2) AS fraud_value
FROM transactions
GROUP BY transaction_type
ORDER BY fraud_transactions DESC;
