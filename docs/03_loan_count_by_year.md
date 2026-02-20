# Loan Count by Year Profiling Scorecard (raw.loan_count_by_year)

## Purpose
This document provides a lightweight **data profiling / data quality** summary for `raw.loan_count_by_year`.
Unlike `raw.loans` (row-level transactional data), this table is an **aggregated time-series** at **year grain**
(i.e., **one row per `issue_year`**). The goal is to validate that the series is structurally sound and safe to use
for trend analysis (e.g., YoY comparisons).

## Table Grain and Assumptions
- **Grain:** 1 row per `issue_year`
- **Measure:** `loan_count` = number of loans issued in that year
- **Expected properties:**
  - `issue_year` should be a whole-number year (integer after normalization)
  - `loan_count` should be a positive integer
  - No duplicate `issue_year` values (unique key)
  - No missing years **within the observed min–max range** (optional check)

## Metric Definitions (v1)
For each column, we use three mutually exclusive buckets:

- **Missing:** `NULL`
- **Mismatched:** value is present but violates an explicit rule  
  - `issue_year`: not a whole number year, or outside a reasonable range (1900–2100)
  - `loan_count`: `<= 0`
- **Valid:** `total_rows - missing_cnt - mismatched_cnt`

> Note: This is a **profiling** report (observe + flag). It does not attempt to correct values.

---

## 1) Column Scorecard

```text
column_name|total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|
-----------+----------+---------+---------+--------------+--------------+-----------+-----------+
issue_year |         8|        8|   100.00|             0|          0.00|          0|       0.00|
loan_count |         8|        8|   100.00|             0|          0.00|          0|       0.00|
```

**Interpretation**
- Both columns are **100% valid** under the v1 rules.
- No missing values and no rule violations were detected in this aggregated table.

---

## 2) Dataset Summary

```text
year_rows|min_year|max_year|total_loans|min_loan_count|max_loan_count|
---------+--------+--------+-----------+--------------+--------------+
        8|    2012|    2019|     270299|          2594|         51737|
```

**Interpretation**
- The series covers **2012–2019** (8 years).
- The total across all years is **270,299 loans**, which should reconcile to the parent dataset (e.g., `raw.loans`)
  if this aggregation was derived from it.
- The smallest yearly volume is **2,594** (2012) and the largest is **51,737** (2019).

---

## 3) Raw Values (as imported)

```text
issue_year|loan_count|
----------+----------+
    2017.0|     44435|
    2019.0|     51737|
    2013.0|     13460|
    2018.0|     49333|
    2014.0|     23453|
    2016.0|     43368|
    2015.0|     41919|
    2012.0|      2594|
```

**Note on `issue_year` formatting**
- Values appear with a decimal suffix (e.g., `2017.0`) due to CSV import typing.
- This is acceptable as long as the value is a whole number year; we normalize it to an integer during profiling.

---

## Key Takeaways (Portfolio-ready)
- `raw.loan_count_by_year` is a **clean, low-risk** aggregate table suitable for simple yearly trend reporting.
- The dataset passes basic **completeness** and **sanity** checks under v1 rules.
- For deeper validation, optional checks include:
  - **Uniqueness:** verify no duplicate `issue_year`
  - **Series completeness:** verify no missing years within 2012–2019
  - **Reconciliation:** verify `SUM(loan_count)` matches the parent dataset row count
