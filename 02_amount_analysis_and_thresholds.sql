-- 02: Transaction amount analysis and threshold testing
USE fraud_analytics_project;

-- Compare transaction amount distributions for fraud vs genuine
SELECT
    is_fraud,
    COUNT(*) AS transaction_count,
    ROUND(MIN(amount), 2) AS min_amount,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(MAX(amount), 2) AS max_amount,
    ROUND(SUM(amount), 2) AS total_amount
FROM transactions
GROUP BY is_fraud
ORDER BY is_fraud;

-- Threshold comparison: amount-based rule
WITH thresholds AS (
    SELECT 5000 AS threshold_amount
    UNION ALL SELECT 10000
    UNION ALL SELECT 15000
    UNION ALL SELECT 20000
),
evaluations AS (
    SELECT
        th.threshold_amount,
        COUNT(CASE WHEN t.amount > th.threshold_amount THEN 1 END) AS flagged,
        COUNT(CASE WHEN t.amount > th.threshold_amount AND t.is_fraud = 1 THEN 1 END) AS fraud_caught,
        COUNT(CASE WHEN t.amount > th.threshold_amount AND t.is_fraud = 0 THEN 1 END) AS false_positives,
        COUNT(CASE WHEN t.amount <= th.threshold_amount AND t.is_fraud = 1 THEN 1 END) AS false_negatives,
        COUNT(CASE WHEN t.amount <= th.threshold_amount AND t.is_fraud = 0 THEN 1 END) AS true_negatives
    FROM thresholds th
    CROSS JOIN transactions t
    GROUP BY th.threshold_amount
)
SELECT
    threshold_amount,
    flagged,
    fraud_caught,
    false_positives,
    ROUND(fraud_caught * 100.0 / NULLIF(flagged, 0), 2) AS precision_pct,
    ROUND(fraud_caught * 100.0 / NULLIF(fraud_caught + false_negatives, 0), 2) AS recall_pct
FROM evaluations
ORDER BY threshold_amount;
