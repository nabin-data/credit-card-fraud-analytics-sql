-- 03: Card-level transaction frequency and velocity
USE fraud_analytics_project;

-- Monthly card frequency (for the dataset's period)
SELECT
    card_id,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN is_fraud = 1 THEN 1 END) AS fraud_transactions,
    ROUND(SUM(amount), 2) AS total_amount,
    MIN(transaction_timestamp) AS first_transaction,
    MAX(transaction_timestamp) AS last_transaction
FROM transactions
GROUP BY card_id
HAVING COUNT(*) >= 10
ORDER BY fraud_transactions DESC, total_transactions DESC;

-- Inspect chronological transactions for a known suspicious card
SELECT
    transaction_id,
    card_id,
    transaction_timestamp,
    amount,
    merchant_category,
    transaction_type,
    city,
    is_fraud,
    LAG(transaction_timestamp) OVER (
        PARTITION BY card_id ORDER BY transaction_timestamp
    ) AS previous_transaction_timestamp,
    TIMESTAMPDIFF(
        SECOND,
        LAG(transaction_timestamp) OVER (
            PARTITION BY card_id ORDER BY transaction_timestamp
        ),
        transaction_timestamp
    ) AS seconds_since_previous
FROM transactions
WHERE card_id = 'CARDVEL90001'
ORDER BY transaction_timestamp;

-- Rolling 5-minute transaction count per card
WITH velocity AS (
    SELECT
        transaction_id,
        card_id,
        transaction_timestamp,
        amount,
        is_fraud,
        COUNT(*) OVER (
            PARTITION BY card_id
            ORDER BY transaction_timestamp
            RANGE BETWEEN INTERVAL 5 MINUTE PRECEDING AND CURRENT ROW
        ) AS transactions_in_5_minutes
    FROM transactions
)
SELECT
    card_id,
    transaction_id,
    transaction_timestamp,
    amount,
    is_fraud,
    transactions_in_5_minutes
FROM velocity
WHERE transactions_in_5_minutes >= 3
ORDER BY transactions_in_5_minutes DESC, card_id, transaction_timestamp;

-- Evaluate velocity-only rule (>=3 transactions in 5-minute rolling window)
WITH velocity AS (
    SELECT
        transaction_id,
        card_id,
        transaction_timestamp,
        amount,
        is_fraud,
        COUNT(*) OVER (
            PARTITION BY card_id
            ORDER BY transaction_timestamp
            RANGE BETWEEN INTERVAL 5 MINUTE PRECEDING AND CURRENT ROW
        ) AS transactions_in_5_minutes
    FROM transactions
),
scored AS (
    SELECT *, CASE WHEN transactions_in_5_minutes >= 3 THEN 1 ELSE 0 END AS flagged
    FROM velocity
)
SELECT
    COUNT(CASE WHEN flagged = 1 THEN 1 END) AS flagged_transactions,
    COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) AS true_positives,
    COUNT(CASE WHEN flagged = 1 AND is_fraud = 0 THEN 1 END) AS false_positives,
    COUNT(CASE WHEN flagged = 0 AND is_fraud = 1 THEN 1 END) AS false_negatives,
    COUNT(CASE WHEN flagged = 0 AND is_fraud = 0 THEN 1 END) AS true_negatives,
    ROUND(SUM(CASE WHEN flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END), 2) AS fraud_value_captured,
    ROUND(
        COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN flagged = 1 THEN 1 END), 0), 2
    ) AS precision_pct,
    ROUND(
        COUNT(CASE WHEN flagged = 1 AND is_fraud = 1 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN is_fraud = 1 THEN 1 END), 0), 2
    ) AS recall_pct
FROM scored;
