-- 04: Customer spending baseline and anomaly rule
USE fraud_analytics_project;

-- Genuine transaction baseline by customer
SELECT
    customer_id,
    COUNT(*) AS genuine_transactions,
    ROUND(AVG(amount), 2) AS average_transaction_amount,
    ROUND(MAX(amount), 2) AS highest_transaction_amount,
    ROUND(SUM(amount), 2) AS total_genuine_spending
FROM transactions
WHERE is_fraud = 0
GROUP BY customer_id
ORDER BY average_transaction_amount DESC;

-- Flag transactions >3x customer's average genuine amount
WITH customer_baseline AS (
    SELECT
        customer_id,
        AVG(amount) AS avg_genuine_amount
    FROM transactions
    WHERE is_fraud = 0
    GROUP BY customer_id
),
scored AS (
    SELECT
        t.transaction_id,
        t.customer_id,
        t.amount,
        t.is_fraud,
        b.avg_genuine_amount,
        t.amount / NULLIF(b.avg_genuine_amount, 0) AS amount_multiple,
        CASE WHEN t.amount > 3 * b.avg_genuine_amount THEN 1 ELSE 0 END AS flagged
    FROM transactions t
    JOIN customer_baseline b
      ON t.customer_id = b.customer_id
)
SELECT
    COUNT(CASE WHEN flagged = 1 THEN 1 END) AS flagged_transactions,
    COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) AS fraud_caught,
    COUNT(CASE WHEN flagged = 1 AND is_fraud = 0 THEN 1 END) AS false_positives,
    ROUND(
        COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN flagged = 1 THEN 1 END), 0), 2
    ) AS precision_pct,
    ROUND(
        COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN is_fraud = 1 THEN 1 END), 0), 2
    ) AS recall_pct,
    ROUND(SUM(CASE WHEN flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END), 2) AS fraud_value_captured
FROM scored;

-- NOTE: This portfolio analysis uses the dataset's genuine labels to create a retrospective baseline.
-- A production system must use only information available before each scored transaction
-- (time-based / point-in-time baseline) to avoid future-data leakage.
