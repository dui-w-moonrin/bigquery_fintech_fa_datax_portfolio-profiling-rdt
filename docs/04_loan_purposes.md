# Loan Purposes Reference Profiling (raw.loan_purposes)

## Purpose
This document provides a lightweight **reference-table profiling** summary for `raw.loan_purposes`.
This table is a **domain/lookup list** (similar to a VLOOKUP mapping list): it defines the allowed values
for the `purpose` field, and is primarily used for **validation, standardization, and mapping**.

## Table Grain and Intended Use
- **Grain:** 1 row per allowed `purpose` value (no counts in this table)
- **Primary use cases:**
  - Validate that `raw.loans.purpose` contains only approved values
  - Standardize naming (trim/case) and support downstream mapping to reporting categories
  - Provide a stable reference set for documentation and test cases

## Metric Definitions (v1)
For a reference/domain table, the key quality dimensions are:

- **Missing:** `purpose` is `NULL` or blank after trimming.
- **Mismatched:** (v1) none enforced beyond non-blank (kept simple for a domain list).
  - Optional future rule (v2): enforce a strict format such as `lower_snake_case`.
- **Valid:** `total_rows - missing_cnt - mismatched_cnt`.
- **Unique:** number of distinct values among non-missing rows (after basic normalization such as `TRIM` + `LOWER`).

---

## 1) Column Scorecard

```text
column_name|total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|unique_cnt|unique_pct|
-----------+----------+---------+---------+--------------+--------------+-----------+-----------+----------+----------+
purpose    |        13|       13|   100.00|             0|          0.00|          0|       0.00|        13|    100.00|
```

**Interpretation**
- The domain list is **complete** (no NULL/blank values).
- The domain list is **unique** (no duplicates detected under v1 normalization).
- This table is considered **low-risk** and safe to use as a validation reference.

---

## 2) Allowed Values (as imported)

```text
purpose           |
------------------+
car               |
credit_card       |
debt_consolidation|
home_improvement  |
house             |
major_purchase    |
medical           |
moving            |
other             |
renewable_energy  |
small_business    |
vacation          |
wedding           |
```

## Key Takeaways (Portfolio-ready)
- `raw.loan_purposes` is a **clean reference/domain table** used to validate and standardize loan purpose values.
- It passes basic completeness and uniqueness checks, making it suitable for:
  - **Enum validation** in profiling scorecards
  - **Mapping** to reporting categories (if needed)
  - **UAT / test case** design (allowed-values list)

