# Loan With Region Profiling (raw.loan_with_region)

## Purpose
This document provides a lightweight **data profiling / data quality** summary for `raw.loan_with_region`.
The table appears to be a derived “enriched” dataset that attaches a **region** attribute to each loan record.

## Table Grain and Assumptions
- **Grain:** 1 row per `loan_id`
- **Key column:** `loan_id`
- **Measures/attributes:**
  - `loan_amount` (numeric)
  - `region` (categorical enum)

**Expected properties (v1):**
- `loan_id` should be present, positive, and **unique** (no duplicates)
- `loan_amount` should be present and **positive**
- `region` should be present and belong to an allowed set (e.g., `South`, `West`, `Northeast`, `Midwest`)
- The table should **reconcile** to `raw.loans` at `loan_id` level (same row count + distinct IDs)

## Metric Definitions (v1)
For each column, we use three mutually exclusive buckets:

- **Missing:** `NULL` (or blank after trimming for text)
- **Mismatched:** present but violates an explicit rule
  - `loan_id`: `<= 0` and/or duplicates (non-missing count minus distinct count)
  - `region`: not in the allowed enum set
  - `loan_amount`: `<= 0`
- **Valid:** `total_rows - missing_cnt - mismatched_cnt`

In addition:
- **Unique:** number of distinct values among non-missing rows (for `loan_id`, this should equal total rows)
- **Most common:** top-1 value frequency (useful for categorical columns such as `region`)

---

## 1) Text/ID Scorecard (loan_id, region)

```text
column_name|total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|unique_cnt|unique_pct|most_common_cnt|most_common_pct|most_common_value|
-----------+----------+---------+---------+--------------+--------------+-----------+-----------+----------+----------+---------------+---------------+-----------------+
loan_id    |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|    270299|    100.00|              1|           0.00|1                |
region     |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|         4|      0.00|          97683|          36.14|South            |
```

**Interpretation**
- `loan_id` is **100% valid** and **fully unique** (no duplicates / no missing).
- `region` is **100% valid** under the v1 enum rule, with **4 distinct values**.
- The most common region is **South (36.14%)**, indicating a non-uniform distribution across regions.

> Note on `unique_pct` for categorical enums: uniqueness is not expected to be high; the number of distinct values
reflects the size of the domain (here, 4 regions).

---

## 2) Numeric Scorecard (loan_amount)

```text
column_name|total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|mean    |std    |min    |p25    |p50     |p75     |max     |
-----------+----------+---------+---------+--------------+--------------+-----------+-----------+--------+-------+-------+-------+--------+--------+--------+
loan_amount|    270299|   270299|   100.00|             0|          0.00|          0|       0.00|15412.83|9459.78|1000.00|8000.00|13200.00|20300.00|40000.00|
```

**Interpretation**
- `loan_amount` has **no missing values** and **no non-positive values** under v1 rules.
- The distribution shows a typical right-skew for loan amounts (mean > median is common in such data).
- Key percentiles provide stable “sanity anchors” for downstream checks (e.g., UAT spot checks).

---

## 3) Reconciliation to raw.loans (loan_id level)

```text
loan_with_region_rows|loan_with_region_distinct_loan_id|loans_rows|loans_distinct_loan_id|
---------------------+---------------------------------+----------+----------------------+
               270299|                           270299|    270299|                270299|
```

**Interpretation**
- `raw.loan_with_region` matches `raw.loans` exactly by **row count** and **distinct `loan_id`**.
- This strongly suggests the dataset is a **one-to-one enrichment** of the loans table (no missing mappings and no extras).

---

## 4) Region Distribution

```text
region_norm|cnt  |pct  |
-----------+-----+-----+
South      |97683|36.14|
West       |69137|25.58|
Northeast  |55014|20.35|
Midwest    |48465|17.93|
```

**Interpretation**
- Regional volumes are reasonably spread across the 4 regions, with **South** as the largest share.
- This distribution can be reused as a baseline for future regressions (e.g., if the pipeline changes, large shifts may indicate mapping issues).

---

## Key Takeaways (Portfolio-ready)
- `raw.loan_with_region` is a **clean, reconciled enrichment table** at loan grain (1 row per `loan_id`).
- Core columns pass completeness and sanity checks under v1 rules (no missing / no mismatches detected).
- The dataset is ready for:
  - Region-based segmentation (counts, amounts)
  - Trend analysis (when joined to issue dates)
  - UAT validation (row-level reconciliation + distribution baselines)
