# Portfolio Project Summary

## Preferred strategy
**Transaction amount > ₹15,000 OR at least 3 transactions in a rolling 5-minute window on the same card.**

| Metric | Result |
|---|---:|
| Transactions | 5,000 |
| Fraud transactions | 138 |
| Fraud rate | 2.76% |
| Alerts | 76 |
| True positives | 75 |
| False positives | 1 |
| False negatives | 63 |
| True negatives | 4,861 |
| Precision | 98.68% |
| Recall | 54.35% |
| Fraud value captured | ₹3,017,445.99 |
| Fraud value capture rate | 98.66% |

## Why selected
Compared with the four-signal OR strategy, the preferred strategy generated 76 alerts rather than 209, with 1 FP rather than 131. It caught 3 fewer fraud transactions and captured about ₹10,937.66 less fraud transaction value.

**Synthetic-data caveat:** These metrics describe this engineered dataset and are not expected to generalize to production.
