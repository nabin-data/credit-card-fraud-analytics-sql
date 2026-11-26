-- 05: Device-level fraud analysis and rule evaluation
USE fraud_analytics_project;

-- Devices used by multiple customers/cards
SELECT
    device_id,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT card_id) AS unique_cards,
    COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS fraud_transactions,
    ROUND(
        COUNT(CASE WHEN is_fraud = 1 THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS fraud_rate_pct,
    ROUND(SUM(amount), 2) AS total_transaction_amount,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2) AS fraud_amount
FROM transactions
GROUP BY device_id
HAVING COUNT(*) >= 2
ORDER BY fraud_transactions DESC, unique_customers DESC;

-- Rule A: Flag devices shared by >=3 distinct customers
WITH device_risk AS (
    SELECT
        device_id,
        COUNT(*) AS total_transactions,
        COUNT(DISTINCT customer_id) AS unique_customers,
        COUNT(DISTINCT card_id) AS unique_cards,
        COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS fraud_transactions
    FROM transactions
    GROUP BY device_id
),
scored AS (
    SELECT
        t.*,
        d.unique_customers,
        CASE WHEN d.unique_customers >= 3 THEN 1 ELSE 0 END AS flagged
    FROM transactions t
    JOIN device_risk d ON t.device_id = d.device_id
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
    ROUND(SUM(CASE WHEN flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END), 2)
        AS fraud_amount_captured
FROM scored
WHERE flagged = 1;

-- Rule B: Shared device (>=3 customers) AND transaction amount >₹5,000
WITH device_risk AS (
    SELECT
        device_id,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM transactions
    GROUP BY device_id
),
scored AS (
    SELECT
        t.*,
        d.unique_customers,
        CASE
            WHEN d.unique_customers >= 3 AND t.amount > 5000 THEN 1
            ELSE 0
        END AS flagged
    FROM transactions t
    JOIN device_risk d ON t.device_id = d.device_id
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
    ROUND(SUM(CASE WHEN flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END), 2)
        AS fraud_amount_captured
FROM scored
WHERE flagged = 1;
