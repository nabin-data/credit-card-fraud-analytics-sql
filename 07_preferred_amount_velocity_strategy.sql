-- 07: Preferred strategy: Amount + Velocity
-- Recommended from this synthetic dataset due to its precision / alert-volume trade-off.
USE fraud_analytics_project;

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
    SELECT
        *,
        CASE
            WHEN amount > 15000 OR transactions_in_5_minutes >= 3
            THEN 1 ELSE 0
        END AS is_flagged
    FROM velocity
)
SELECT
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN is_flagged = 1 THEN 1 END) AS flagged_transactions,
    COUNT(CASE WHEN is_flagged = 1 AND is_fraud = 1 THEN 1 END) AS true_positives,
    COUNT(CASE WHEN is_flagged = 1 AND is_fraud = 0 THEN 1 END) AS false_positives,
    COUNT(CASE WHEN is_flagged = 0 AND is_fraud = 1 THEN 1 END) AS false_negatives,
    COUNT(CASE WHEN is_flagged = 0 AND is_fraud = 0 THEN 1 END) AS true_negatives,
    ROUND(
        COUNT(CASE WHEN is_flagged = 1 AND is_fraud = 1 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN is_flagged = 1 THEN 1 END), 0), 2
    ) AS precision_pct,
    ROUND(
        COUNT(CASE WHEN is_flagged = 1 AND is_fraud = 1 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN is_fraud = 1 THEN 1 END), 0), 2
    ) AS recall_pct,
    ROUND(
        COUNT(CASE WHEN is_flagged = 0 AND is_fraud = 0 THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN is_fraud = 0 THEN 1 END), 0), 2
    ) AS specificity_pct,
    ROUND(
        (COUNT(CASE WHEN is_flagged = 1 AND is_fraud = 1 THEN 1 END) +
         COUNT(CASE WHEN is_flagged = 0 AND is_fraud = 0 THEN 1 END)) * 100.0 /
        COUNT(*), 2
    ) AS accuracy_pct,
    ROUND(SUM(CASE WHEN is_flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END), 2)
        AS fraud_value_captured,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2) AS total_fraud_value,
    ROUND(
        SUM(CASE WHEN is_flagged = 1 AND is_fraud = 1 THEN amount ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 0), 2
    ) AS fraud_value_capture_pct
FROM scored;
