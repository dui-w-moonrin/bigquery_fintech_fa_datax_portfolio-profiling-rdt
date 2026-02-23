# Profiling Report: State → Subregion → Region (Mapping)

## Purpose
Reference-table profiling for a small mapping table used to enrich datasets. Focus: locked domains + cross-field mapping consistency.

---

This document summarizes **data profiling / data quality** results for `raw.state_region`, a small reference/lookup table that maps:

- `state` → `subregion` → `region`

This mapping can be used to enrich other tables (e.g., converting a state code into a broader reporting region).

---

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
For each column:
- **Missing:** `NULL` / blank after trimming
- **Mismatched:** present but violates a locked rule
  - `state`: not matching `^[A-Z]{2}$` OR equals header-like text (`state`)
  - `subregion`: not in the allowed 9 division names OR equals header-like text (`subregion`)
  - `region`: not in the allowed 4 values OR equals header-like text (`region`)
- **Valid:** `total_rows - missing_cnt - mismatched_cnt`

Additional metrics:
- **Unique:** `COUNT(DISTINCT ...)` among non-missing
- **Most common:** top-1 value frequency

---

## 2) Locked rules per column (what we consider "mismatched")
_otherwise state 'No additional locked rules beyond type normalization'_

## 3) Latest scorecard outputs
### 3.1 Text / categorical columns


column_name|total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|unique_cnt|unique_pct|most_common_cnt|most_common_pct|most_common_value|
-----------+----------+---------+---------+--------------+--------------+-----------+-----------+----------+----------+---------------+---------------+-----------------+
state      |        52|       51|    98.08|             1|          1.92|          0|       0.00|        52|    100.00|              1|           1.92|AK               |
subregion  |        52|       51|    98.08|             1|          1.92|          0|       0.00|        10|     19.23|              9|          17.31|South Atlantic   |
region     |        52|       51|    98.08|             1|          1.92|          0|       0.00|         5|      9.62|             17|          32.69|South            |


### Interpretation
- The table contains **52 rows** in total, while **51 rows** are valid for each of the three columns.
- There is **1 mismatched row (1.92%)** consistently across `state`, `subregion`, and `region`.
- No missing values were found.

#### Why `state` shows `unique_cnt = 52` even though only 51 are valid
- `unique_cnt` counts distinct values among non-missing rows.
- The mismatched row contains a distinct value (e.g., literal text like `state`), so the distinct count becomes 52.
- This is expected behavior for profiling and helps confirm the anomaly is a unique outlier.

#### Why `most_common_value` for `state` is not meaningful here
- For a reference key, each valid state typically appears once.
- Therefore the “most common” state will have count 1 (1.92%), which is not informative beyond confirming the table grain.

---

## Finding Summary
- **Finding:** A single anomalous row exists that behaves like a duplicated header line embedded as data.
- **Impact:** If used in joins/enrichment, this row could create incorrect mappings for one record (or cause unexpected categories in reports).
- **Severity:** Low (1 row), but worth documenting because reference tables should be clean and stable.

---

## 4) Distribution snapshots (Top-N evidence)

state_region_norm|cnt|pct |
-----------------+---+----+
AK               |  1|1.92|
AL               |  1|1.92|
AR               |  1|1.92|
AZ               |  1|1.92|
CA               |  1|1.92|
...

**Interpretation:** Supports the expected grain (1 row per state), except for one extra anomaly row.

### Subregions

South Atlantic    |  9|17.31|
Mountain          |  8|15.38|
West North Central|  7|13.46|
New England       |  6|11.54|
East North Central|  5| 9.62|
Pacific           |  5| 9.62|
East South Central|  4| 7.69|
West South Central|  4| 7.69|
Middle Atlantic   |  3| 5.77|
subregion         |  1| 1.92|

**Interpretation:** The unexpected value `subregion` appears once, reinforcing the “embedded header row” hypothesis.

### Regions

South      | 17|32.69|
West       | 13|25.00|
Midwest    | 12|23.08|
Northeast  |  9|17.31|
region     |  1| 1.92|

**Interpretation:** The unexpected value `region` appears once, consistent with the same anomalous row.

---

## 5) Notes / Key findings (high signal)
_(todo: list 3–6 high-signal observations + where to look next)_

## 6) Next checks / TODO
- Add cross-table integrity checks (FK orphans / joinability) where applicable
- Add reconciliation controls (control totals) for derived/reporting tables
- Promote reusable rules into SQL validation pack

---

## Appendix: Raw notes kept from the original file
**Repo:** `bigquery_fintech_fa_datax_portfolio-profiling-rdt`  
**Table:** `raw.state_region`  
**Updated (refactor):** 2026-02-20

---

## Table Grain and Expectations (v1)
- **Grain:** 1 row per US `state` code (2-letter)
- **Expected domains:**
  - `state`: exactly 2 uppercase letters (e.g., `CA`, `NY`)
  - `subregion`: one of the 9 US Census divisions
  - `region`: one of 4 values (`Northeast`, `Midwest`, `South`, `West`)
- **Expected uniqueness:** `state` should be unique (reference key)

> Note: Because this repo focuses on **Profiling + RDT**, we do not “fix” the raw table in this step. We only detect, document, and recommend handling for downstream layers.

---

## Cross-field Validation (subregion → region)
We validated that each `subregion` maps to the correct `region`:

- `New England`, `Middle Atlantic` → `Northeast`
- `East North Central`, `West North Central` → `Midwest`
- `South Atlantic`, `East South Central`, `West South Central` → `South`
- `Mountain`, `Pacific` → `West`

**Exception result:**
```text
subregion_norm|region_norm|cnt|
--------------+-----------+---+
subregion     |Region     |  1|
```

### Interpretation
- Exactly **one** `(subregion, region)` pair violates the mapping rules.
- The pair looks like **embedded header text** (e.g., `subregion`, `Region`), which indicates a data-quality artifact rather than a genuine mapping record.

---

## Recommended Handling (Later, Not in Profiling Step)
To keep the profiling phase pure, we do **not** modify `raw.state_region` here.  
For downstream usage (e.g., RDT mapping or enrichment), recommended filters are:

- `LOWER(state) <> 'state'`
- `LOWER(subregion) <> 'subregion'`
- `LOWER(region) <> 'region'`

This preserves raw evidence while ensuring clean mapping behavior in derived outputs.
