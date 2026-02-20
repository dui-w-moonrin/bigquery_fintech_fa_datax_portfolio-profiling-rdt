# Profiling Report: Loans

## Purpose
Column-level profiling scorecard for `raw.loans` plus a few **targeted evidence checks** that are high-signal for Functional Analyst work (definitions, reconciliation mindset, and “prove it with queries”).

This document summarizes a **data-profiling / data-quality scorecard** for the `raw.loans` dataset.
It is designed to be **Functional Analyst–friendly**: clear definitions, repeatable checks, and concise findings.

## 1) Scope & Definitions (applies to every column)
**Scorecard fields**
- **Missing**: NULL / blank after trimming (and normalization rules stated per column if any)
- **Mismatched**: violates a locked rule / expected domain for that column
- **Valid**: total − missing − mismatched
- **Unique**: distinct count of normalized values
- **Most common**: mode value and its share (applies mainly to text/categorical columns)

**Column type conventions**
- **Text / categorical** columns usually report: missing/mismatched/valid/unique/most_common_value (+ share)
- **Numeric** columns usually report: missing/mismatched/valid/unique plus **mean | std | min | p25 | p50 | p75 | max**

### 1.3 Dataset-specific notes
The scorecard uses **three mutually exclusive buckets** per column:
- **Missing**: `NULL` (and for text fields, blank/whitespace after trimming)
- **Mismatched**: value is present but violates an explicit rule (format / enum / range / parse)
- **Valid**: `total_rows - missing_cnt - mismatched_cnt`

Additional metrics:
- **Unique**: `COUNT(DISTINCT value)` among non-missing rows
- **Most common**: top-1 value (count + percent) among non-missing rows

> Profiling = observe + flag. This report does not “fix” data.

---

The scorecard uses **three mutually exclusive buckets** per column:

- **Missing**: `NULL` (and for text fields, blank/whitespace after trimming).
- **Mismatched**: values that are present but violate an explicit rule (examples: out-of-range numeric, invalid enum value, invalid format).
- **Valid**: `total_rows - missing_cnt - mismatched_cnt`.

Additional metrics:
- **Unique**: `COUNT(DISTINCT value)` among **non-missing** rows.
- **Most common**: the top-1 value among **non-missing** rows, with count and percent.

> Note: This is a **profiling** report (observe + flag). It does not “fix” data.

## 2) Locked rules per column (what we consider "mismatched")
_(todo: list per-column locked rules, if any; otherwise state 'No additional locked rules beyond type normalization')_

## 3) Latest scorecard outputs
### 3.1 Text / categorical columns

column_name|total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|unique_cnt|unique_pct|most_common_cnt|most_common_pct|most_common_value|
-----------+----------+---------+---------+--------------+--------------+-----------+-----------+----------+----------+---------------+---------------+-----------------+
loan_id    |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|    270299|    100.00|              1|           0.00|1                |
customer_id|    270299|   270299|   100.00|             0|          0.00|          0|       0.00|    270299|    100.00|              1|           0.00|b'' xfa:xf8)"x...|
loan_status|    270299|   270299|   100.00|             0|          0.00|          0|       0.00|         7|      0.00|         170461|          63.06|Current          |
state      |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|        51|      0.02|          37024|          13.70|CA               |
term       |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|         2|      0.00|         189772|          70.21|36 months        |
grade      |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|         7|      0.00|          79072|          29.25|B                |

---

### 3.2 Numeric columns

column_name  |total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|mean    |std    |min    |p25    |p50     |p75     |max     |
-------------+----------+---------+---------+--------------+--------------+-----------+-----------+--------+-------+-------+-------+--------+--------+--------+
loan_amount  |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|15412.83|9459.78|1000.00|8000.00|13200.00|20300.00|40000.00|
funded_amount|    270299|   270299|   100.00|             0|          0.00|          0|       0.00|15412.83|9459.78|1000.00|8000.00|13200.00|20300.00|40000.00|
int_rate     |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|    0.13|   0.05|   0.05|   0.09|    0.13|    0.16|    0.31|
installment  |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|  453.92| 272.34|  29.52| 256.04|  383.96|  605.12| 1719.83|

## 4) Distribution snapshots (Top-N evidence)

loan_status_norm  |cnt   |pct  |
------------------+------+-----+
Current           |170461|63.06|
Fully Paid        | 76361|28.25|
Charged Off       | 17851| 6.60|
Late (31-120 days)|  3174| 1.17|
In Grace Period   |  1638| 0.61|
Late (16-30 days) |   802| 0.30|
Default           |    12| 0.00|

state_norm|cnt  |pct  |
----------+-----+-----+
CA        |37024|13.70|
TX        |22541| 8.34|
NY        |21854| 8.09|
FL        |19846| 7.34|
IL        |10845| 4.01|
NJ        | 9825| 3.63|
PA        | 9102| 3.37|
OH        | 9080| 3.36|
GA        | 8816| 3.26|
NC        | 7531| 2.79|
VA        | 7477| 2.77|
MI        | 7008| 2.59|
AZ        | 6516| 2.41|
MD        | 6312| 2.34|
MA        | 6117| 2.26|
CO        | 5732| 2.12|
WA        | 5495| 2.03|
MN        | 4782| 1.77|
IN        | 4604| 1.70|
TN        | 4417| 1.63|

grade_norm|cnt  |pct  |
----------+-----+-----+
B         |79072|29.25|
C         |75840|28.06|
A         |57871|21.41|
D         |38876|14.38|
E         |13429| 4.97|
F         | 4005| 1.48|
G         | 1206| 0.45|

loans_customer_not_in_customers_cnt|
-----------------------------------+
                                  0|

min_loan_cnt|p50_loan_cnt|p90_loan_cnt|max_loan_cnt|
------------+------------+------------+------------+
           1|         1.0|         1.0|           1|

## 5) Notes / Key findings (high signal)
## Key Findings (high signal)
- **Funding duplication:** `funded_amount` equals `loan_amount` for **100%** of rows (see the equality check below).  
  This dataset therefore **does not represent partial funding scenarios** (either a business assumption or a mapping duplication).
- **Interest rate encoding:** `int_rate` behaves like a **fraction** (e.g., 0.13 ≈ 13%), not a percentage.
- **Business consistency:** `grade` shows a clean **risk ladder** (A lowest rates → G highest), suggesting grade labeling aligns with pricing.
- **Term & installment sanity:** 60-month loans have higher average loan amount and higher average installment than 36-month loans, which is consistent.

---

## 4) Targeted Checks (Evidence)
### 4.1 funded_amount equals loan_amount

total_rows|eq_cnt|eq_pct|diff_cnt|
----------+------+------+--------+
    270299|270299|100.00|       0|

### 4.2 Distinct counts (loan_amount vs funded_amount)

total_rows|loan_amount_distinct|funded_amount_distinct|
----------+--------------------+----------------------+
    270299|                1543|                  1543|

### 4.3 Term vs installment sanity (aggregate)

term      |cnt   |avg_installment|p50_installment|avg_loan_amount|
----------+------+---------------+---------------+---------------+
 36 months|189772|         430.09|         340.18|       12988.51|
 60 months| 80527|         510.08|         474.31|       21126.03|

### 4.4 Interest rate ladder by grade

grade|cnt  |avg_int_rate|p50_int_rate|min_int_rate|max_int_rate|
-----+-----+------------+------------+------------+------------+
A    |57871|      0.0724|      0.0735|      0.0531|      0.0925|
B    |79072|      0.1085|      0.1099|      0.0600|      0.1409|
C    |75840|      0.1441|      0.1430|      0.0600|      0.1774|
D    |38876|      0.1881|      0.1825|      0.0600|      0.2880|
E    |13429|      0.2203|      0.2170|      0.0600|      0.2900|
F    | 4005|      0.2577|      0.2499|      0.0600|      0.3075|
G    | 1206|      0.2839|      0.2818|      0.2470|      0.3099|

---

## 6) Next checks / TODO
- Add cross-table integrity checks (FK orphans / joinability) where applicable
- Add reconciliation controls (control totals) for derived/reporting tables
- Promote reusable rules into SQL validation pack

---

## Appendix: Raw notes kept from the original file
**Repo:** `bigquery_fintech_fa_datax_portfolio-profiling-rdt`  
**Table:** `raw.loans`  
**Updated (refactor):** 2026-02-20

---

## How to use this in the portfolio
- Use the **Column Scorecard** table as the primary “at-a-glance” quality view.
- Reference **Targeted Checks** as **evidence** for key findings (especially the funded vs loan duplication).
- Keep this document stable as **v1 profiling**; add stricter rules later only if a business definition requires it.
