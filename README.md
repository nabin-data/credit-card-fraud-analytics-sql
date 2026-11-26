# Credit Card Fraud Detection & Transaction Risk Analytics

**SQL | MySQL 8 | Fraud Analytics | Risk Strategy**

## Project overview

This portfolio project analyzes **5,000 synthetic card transactions** to explore fraud patterns and design/evaluate SQL-based detection rules. The analysis covers merchant category, transaction channel, amount, card velocity, customer spending anomalies, device-sharing patterns, and strategy trade-offs.

The project emphasizes operational strategy—not only detecting fraud, but balancing fraud coverage, alert volume, precision, recall, false positives, and transaction value captured.

> **Dataset disclosure:** The data is synthetic, and some fraud patterns were intentionally planted. Results are illustrative and must not be interpreted as real-world fraud prevalence or production model performance. Fraud value in this project is the value of transactions labeled fraudulent, not confirmed realized loss.

## Dataset

The table `transactions` includes:

| Column | Description |
|---|---|
| `transaction_id` | Unique transaction identifier |
| `customer_id` | Customer identifier |
| `card_id` | Card identifier |
| `transaction_timestamp` | Transaction timestamp |
| `amount` | Transaction amount (INR) |
| `merchant_id` | Merchant identifier |
| `merchant_category` | Merchant category |
| `city` | Transaction city |
| `transaction_type` | Channel/type (e.g., Online, POS, ATM) |
| `card_present` | Card-present indicator |
| `device_id` | Device identifier |
| `is_fraud` | Label: 1 fraud, 0 genuine |

## SQL setup

Create the database/table (if not already created):

```sql
CREATE DATABASE fraud_analytics_project;
USE fraud_analytics_project;

CREATE TABLE transactions (
    transaction_id BIGINT PRIMARY KEY,
    customer_id INT,
    card_id VARCHAR(20),
    transaction_timestamp DATETIME,
    amount DECIMAL(10,2),
    merchant_id VARCHAR(20),
    merchant_category VARCHAR(50),
    city VARCHAR(50),
    transaction_type VARCHAR(20),
    card_present TINYINT,
    device_id VARCHAR(50),
    is_fraud TINYINT
);
```

Import the CSV into this table using MySQL Workbench's Table Data Import Wizard. Ensure column order/types match and the imported row count is 5,000.

## Analysis files

Run the scripts in order:

1. `SQL/01_data_exploration.sql` — dataset overview, fraud distribution, merchant category and channel analysis.
2. `SQL/02_amount_analysis_and_thresholds.sql` — fraud vs genuine amounts; threshold evaluation.
3. `SQL/03_card_velocity.sql` — card frequency, chronological review, rolling 5-minute velocity.
4. `SQL/04_customer_behavior.sql` — genuine customer baseline and 3x spending anomaly rule.
5. `SQL/05_device_analysis.sql` — shared devices and device-rule evaluations.
6. `SQL/06_combined_strategy_comparison.sql` — compare the combined four-signal strategy.
7. `SQL/07_preferred_amount_velocity_strategy.sql` — reproduce the preferred final strategy.

## Key findings

### Dataset overview
- 5,000 transactions
- 138 fraud transactions; fraud rate **2.76%**
- 4,862 genuine transactions
- Fraud-labeled transaction value: **₹3,058,366.61**
- Average fraud transaction: **₹22,162.08**
- Average genuine transaction: **₹997.87**
- Fraud-labeled transaction value was approximately 38.67% of total transaction value.

### Merchant category
The synthetic dataset concentrated fraud in Electronics, Online Services, Fashion, and Travel:
- Electronics: 44 fraud transactions; 8.49% fraud rate.
- Online Services: 33; 6.50%.
- Fashion: 31; 6.11%.
- Travel: 30; 6.02%.
- Travel had the largest fraud transaction value (~₹963,399.92), followed by Fashion (~₹842,547.40).

### Channel
In this dataset, fraud labels appeared in Online transactions:
- Online: 1,732 transactions; 138 fraud; 7.97% fraud rate.
- POS: 1,601 transactions; 0 fraud.
- ATM: 1,667 transactions; 0 fraud.

This is a planted dataset pattern, not a claim that online transactions are universally more fraudulent.

### Amount threshold
The amount-only rule was tested at ₹5,000, ₹10,000, ₹15,000, and ₹20,000. The ₹15,000 threshold yielded 98.39% precision with 44.20% recall in the synthetic dataset, illustrating a high-precision / lower-coverage trade-off.

### Velocity
A rolling 5-minute card-level count was built using a MySQL window frame:
`RANGE BETWEEN INTERVAL 5 MINUTE PRECEDING AND CURRENT ROW`

The rule flags cards with at least 3 transactions in the rolling window. Planted patterns included burst activity and card-testing-like sequences.

### Customer behavior
A retrospective rule flagged transactions exceeding 3x a customer's average genuine transaction amount:
- 193 flagged
- 72 fraud caught
- 121 false positives
- 37.31% precision
- 52.17% recall
- Fraud value captured: ₹3,026,190.65

This rule was noisy and not recommended as a standalone block. In a production design, the baseline must be time-aware and use only information available before the transaction being scored.

### Device analysis
Rule: device used by 3+ unique customers.
- 2,930 flagged
- 93 fraud caught
- 2,837 false positives
- 3.17% precision
- 67.39% recall
- Fraud value captured: ₹1,766,137.77

Refined rule: shared device (3+ customers) AND transaction amount >₹5,000.
- 77 flagged
- 44 fraud caught
- 33 false positives
- 57.14% precision
- 31.88% recall
- Fraud value captured: ₹1,738,748.23

The refined device rule reduced alerts by approximately 97.4% and retained approximately 98.5% of the original device rule's captured fraud value. Device-sharing should be a contextual signal rather than an automatic block.

## Strategy comparison

| Strategy | Alerts | TP | FP | FN | TN | Precision | Recall | Fraud value captured | Fraud value capture |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Amount >₹15,000 OR 5-min velocity ≥3 | 76 | 75 | 1 | 63 | 4,861 | 98.68% | ₹3,017,445.99 | 98.66% |
| All four signals (OR) | 209 | 78 | 131 | 60 | 4,731 | 37.32% | ₹3,028,383.65 | 99.02% |

### Preferred strategy

**Amount >₹15,000 OR 3+ transactions on the same card in a rolling 5-minute window.**

It produced:
- 76 alerts out of 5,000 transactions (1.52% alert rate)
- 75 fraud caught
- 1 false positive
- 98.68% precision
- 54.35% recall
- 98.66% fraud transaction-value capture

Adding customer-behavior and device-sharing signals via OR logic increased alerts from 76 to 209 and caught only 3 additional fraud transactions, while adding 131 false positives. This dataset therefore supports retaining the additional signals as supporting/contextual features rather than broad standalone alert triggers.

## Business recommendations

1. Use amount and velocity as high-confidence alert triggers for this dataset.
2. Use customer baseline and device-sharing as supporting risk signals; consider a risk score or prioritization layer instead of OR-based alerts.
3. Tune thresholds against investigator capacity, customer friction, and fraud value—not accuracy alone.
4. For a production-ready evaluation, use a time-based train/test split, point-in-time features, holdout validation, and cost-sensitive metrics.
5. Validate false-positive rates and rule performance on real, representative, labeled data before deployment.

## Limitations

- Synthetic, small dataset (5,000 rows) with intentionally planted fraud patterns.
- No chargeback, recovery, or confirmed-loss data; labeled transaction amount is not realized loss.
- Retrospective customer baseline uses the dataset's genuine labels and is not point-in-time safe.
- Thresholds were tested on the same dataset used for analysis; no holdout evaluation.
- SQL rules only; no machine-learning model or production deployment.
- No causal conclusions; findings are specific to the data generation patterns.

## Skills demonstrated

MySQL 8, CTEs, joins, aggregation, conditional aggregation, window functions, `LAG`, rolling time windows, rule-based detection, feature analysis, threshold evaluation, confusion matrix, precision, recall, specificity, accuracy, false-positive analysis, fraud-value capture, and risk-strategy trade-off analysis.


