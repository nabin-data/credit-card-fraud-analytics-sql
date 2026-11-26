-- 06: Strategy comparison and final combined strategy
USE fraud_analytics_project;

-- Strategy 1: Amount >₹15,000 OR 5-minute velocity >=3
WITH velocity AS (
    SELECT
        transaction_id,
        COUNT(*) OVER (
            PARTITION BY card_id
            ORDER BY transaction_timestamp
            RANGE BETWEEN INTERVAL 5 MINUTE PRECEDING AND CURRENT ROW
        ) AS transactions_in_5_minutes
    FROM transactions
),
scored AS (
    SELECT
        t.*,
        v.transactions_in_5_minutes,
        CASE
            WHEN t.amount > 15000 OR v.transactions_in_5_minutes >= 3
            THEN 1 ELSE 0
        END AS flagged
    FROM transactions t
    JOIN velocity v ON t.transaction_id = v.transaction_id
)
SELECT
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN flagged = 1 THEN 1 END) AS flagged_transactions,
    COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) AS true_positives,
    COUNT(CASE WHEN flagged = 1 AND is_fraud = 0 THEN 1 END) AS false_positives,
    COUNT(CASE WHEN flagged = 0 AND is_fraud = 1 THEN 1 END) AS false_negatives,
    COUNT(CASE WHEN flagged = 0 AND is_fraud = 0 THEN 1 END) AS true_negatives,
    ROUND(
        COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN flagged = 1 THEN 1 END), 0), 2
    ) AS precision_pct,
    ROUND(
        COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN is_fraud = 1 THEN 1 END), 0), 2
    ) AS recall_pct,
    ROUND(
        SUM(CASE WHEN flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END), 2
    ) AS fraud_value_captured,
    ROUND(
        SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2
    ) AS total_fraud_value,
    ROUND(
        SUM(CASE WHEN flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 0), 2
    ) AS fraud_value_capture_pct
FROM scored;

-- Strategy 2: All four signals combined (OR logic)
WITH velocity AS (
    SELECT
        transaction_id,
        card_id,
        transaction_timestamp,
        COUNT(*) OVER (
            PARTITION BY card_id
            ORDER BY transaction_timestamp
            RANGE BETWEEN INTERVAL 5 MINUTE PRECEDING AND CURRENT ROW
        ) AS transactions_in_5_minutes
    FROM transactions
),
customer_baseline AS (
    SELECT customer_id, AVG(amount) AS avg_genuine_amount
    FROM transactions
    WHERE is_fraud = 0
    GROUP BY customer_id
),
device_risk AS (
    SELECT device_id, COUNT(DISTINCT customer_id) AS unique_customers
    FROM transactions
    GROUP BY device_id
),
signals AS (
    SELECT
        t.transaction_id,
        t.customer_id,
        t.amount,
        t.is_fraud,
        v.transactions_in_5_minutes,
        d.unique_customers,
        c.avg_genuine_amount,
        CASE
            WHEN t.amount > 15000
              OR v.transactions_in_5_minutes >= 3
              OR (d.unique_customers >= 3 AND t.amount > 5000)
              OR t.amount > 3 * c.avg_genuine_amount
            THEN 1 ELSE 0
        END AS is_flagged
    FROM transactions t
    JOIN velocity v ON t.transaction_id = v.transaction_id
    JOIN device_risk d ON t.device_id = d.device_id
    LEFT JOIN customer_baseline c ON t.customer_id = c.customer_id
),
metrics AS (
    SELECT
        COUNT(*) AS total_transactions,
        COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS total_fraud,
        COUNT(CASE WHEN is_fraud = 0 THEN 1 END) AS total_genuine,
        COUNT(CASE WHEN is_flagged = 1 THEN 1 END) AS flagged_transactions,
        COUNT(CASE WHEN is_flagged = 1 AND is_fraud = 1 THEN 1 END) AS true_positives,
        COUNT(CASE WHEN is_flagged = 1 AND is_fraud = 0 THEN 1 END) AS false_positives,
        COUNT(CASE WHEN is_flagged = 0 AND is_fraud = 1 THEN 1 END) AS false_negatives,
        COUNT(CASE WHEN is_flagged = 0 AND is_fraud = 0 THEN 1 END) AS true_negatives,
        SUM(CASE WHEN is_flagged = 1 THEN amount ELSE 0 END) AS total_flagged_amount,
        SUM(CASE WHEN is_flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END) AS fraud_amount_captured,
        SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END) AS total_fraud_amount
    FROM signals
)
SELECT
    total_transactions,
    flagged_transactions,
    true_positives AS fraud_caught,
    false_positives,
    false_negatives,
    true_negatives,
    ROUND(true_positives * 100.0 / NULLIF(flagged_transactions, 0), 2) AS precision_pct,
    ROUND(true_positives * 100.0 / NULLIF(total_fraud, 0), 2) AS recall_pct,
    ROUND(true_negatives * 100.0 / NULLIF(total_genuine, 0), 2) AS specificity_pct,
    ROUND((true_positives + true_negatives) * 100.0 / NULLIF(total_transactions, 0), 2) AS accuracy_pct,
    ROUND(fraud_amount_captured, 2) AS fraud_amount_captured,
    ROUND(total_fraud_amount, 2) AS total_fraud_amount,
    ROUND(fraud_amount_captured * 100.0 / NULLIF(total_fraud_amount, 0), 2) AS fraud_value_capture_pct,
    ROUND(total_flagged_amount, 2) AS total_flagged_amount,
    ROUND(false_positives * 100.0 / NULLIF(flagged_transactions, 0), 2) AS false_positive_rate_of_alerts
FROM metrics;
