# Profiling Report: Customers

**Repo:** `bigquery_fintech_fa_datax_portfolio-profiling-rdt`  
**Table:** `raw.customers`  
**Updated (refactor):** 2026-02-20

---

## Purpose
Column-level profiling scorecard for customer attributes (text + numeric).  
Designed to be **FA/RDT-friendly**: every column has explicit definitions for **Valid / Missing / Mismatched**, plus **Uniqueness** and **Most Common** (mode).

## Definitions (global)
- **total_rows**: number of rows in the table
- **missing_cnt**: `NULL` or blank after trimming (`BTRIM`)
- **mismatched_cnt**: value exists but violates a **locked rule** (pattern / allowed-set / numeric-parse)
- **valid_cnt**: `total_rows - missing_cnt - mismatched_cnt`  
  ✅ therefore `valid_pct + mismatched_pct + missing_pct = 100%`
- **unique_cnt**: `COUNT(DISTINCT value)` among **non-missing** values
- **most_common_value**: top-1 value among non-missing values

> Note: For enum-like columns, `unique_pct` is naturally small. We keep it for consistency across columns.

---

> Repo: **bigquery_fintech**  
> Table: `raw.customers`  
> Generated: 2026-02-18

This page is a **column-level profiling scorecard** for customer attributes (text + numeric).
It is designed to be **FA/RDT-friendly**: each column has clear definitions for **Valid / Mismatched / Missing**, plus **Uniqueness** and **Most Common** (mode).

---

## 1) Definitions (applies to every column)

- **total_rows**: number of rows in the table.
- **missing_cnt**: values that are `NULL` or blank after trimming (`BTRIM()`).
- **mismatched_cnt**: values that exist but **violate a locked rule** (pattern/allowed-set/numeric parse).
- **valid_cnt**: `total_rows - missing_cnt - mismatched_cnt`  
  ✅ therefore `valid_pct + mismatched_pct + missing_pct = 100%`
- **unique_cnt**: `COUNT(DISTINCT value)` among **non-missing** values.
- **most_common_value**: the value with the highest frequency among non-missing values.

> Note: For enum-like columns (e.g., `home_ownership`) `unique_pct` can be very small by definition
> because it is `unique_cnt / non_missing_rows`. We keep it for consistency across all columns.

---

## 2) Locked rules per column (what we consider "mismatched")

### Text / categorical
- `customer_id`  
  - Missing: blank/NULL  
  - Mismatched: contains **control characters** (`[[:cntrl:]]`)  
  - Rationale: values look like byte strings; treat as **opaque ID** and only block obvious bad chars

- `emp_title`  
  - Missing: blank/NULL  
  - Mismatched: *(none in v1)*  
  - Rationale: free-text; in v1 we only measure missing + distribution

- `emp_length`  
  - Missing: blank/NULL or normalized to `n/a`
  - Mismatched: value not in allowed set after normalization  
    Allowed set: `< 1 year`, `1 year`, `2 years`, `3 years`, `4 years`, `5 years`, `6 years`, `7 years`, `8 years`, `9 years`, `10+ years`

- `home_ownership`  
  - Missing: blank/NULL  
  - Mismatched: not in allowed set  
    Allowed set: `MORTGAGE`, `RENT`, `OWN`, `ANY`, `OTHER`, `NONE`

- `verification_status`  
  - Missing: blank/NULL  
  - Mismatched: not in allowed set (case-insensitive)  
    Allowed set: `Source Verified`, `Not Verified`, `Verified`

- `zip_code`  
  - Missing: blank/NULL  
  - Mismatched: does not match pattern `^[0-9]{3}xx$`  
  - Rationale: zip is masked to 3-digit prefix + `xx`

- `addr_state`  
  - Missing: blank/NULL  
  - Mismatched: does not match pattern `^[A-Z]{2}$` (US state-style code)

### Numeric + stats
- `annual_inc`, `annual_inc_joint`, `avg_cur_bal`
  - Missing: blank/NULL
  - Mismatched: cannot be parsed as a number after removing commas and `$`
  - Valid: successfully parsed numeric values
  - Stats (mean/std/min/p25/p50/p75/max) are computed from **valid values only**

---

## 3) Latest scorecard output

### 3.1 Text / categorical columns
```text
Customer Card

column_name        |total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|unique_cnt|unique_pct|most_common_cnt|most_common_pct|most_common_value|
-------------------+----------+---------+---------+--------------+--------------+-----------+-----------+----------+----------+---------------+---------------+-----------------+
customer_id        |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|    270299|    100.00|              1|           0.00|b'' xfa:xf8)"x...|
emp_title          |    270299|   246641|    91.25|             0|          0.00|      23658|       8.75|     83483|     33.85|           4966|           1.84|Teacher          |
emp_length         |    270299|   251554|    93.07|             0|          0.00|      18745|       6.93|        11|      0.00|          88549|          32.76|10+ years        |
home_ownership     |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|         6|      0.00|         133354|          49.34|MORTGAGE         |
verification_status|    270299|   270299|   100.00|             0|          0.00|          0|       0.00|         3|      0.00|         105373|          38.98|source verified  |
zip_code           |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|       887|      0.33|           2897|           1.07|750xx            |
addr_state         |    270299|   270299|   100.00|             0|          0.00|          0|       0.00|        51|      0.02|          37024|          13.70|CA               |

column_name     |total_rows|valid_cnt|valid_pct|mismatched_cnt|mismatched_pct|missing_cnt|missing_pct|mean     |std     |min     |p25     |p50      |p75      |max      |
----------------+----------+---------+---------+--------------+--------------+-----------+-----------+---------+--------+--------+--------+---------+---------+---------+
annual_inc      |    270299|   270212|    99.97|            87|          0.03|          0|       0.00| 78821.95|53349.81|   34.00|47300.00| 66000.00| 95000.00|998000.00|
annual_inc_joint|    270299|    18785|     6.95|             9|          0.00|     251505|      93.05|129787.74|70034.20|15400.00|86588.00|115000.00|154000.00|960000.00|
avg_cur_bal     |    270299|   270299|   100.00|             0|          0.00|          0|       0.00| 13668.80|16753.98|    0.00| 3107.00|  7376.00| 18921.50|623229.00|

emp_title_norm    |cnt  |pct |
------------------+-----+----+
                  |23658|8.75|
Teacher           | 4966|1.84|
Manager           | 4552|1.68|
Owner             | 2460|0.91|
Supervisor        | 2233|0.83|
Registered Nurse  | 2115|0.78|
Driver            | 2052|0.76|
RN                | 1875|0.69|
Sales             | 1682|0.62|
Project Manager   | 1375|0.51|
Office Manager    | 1290|0.48|
General Manager   | 1209|0.45|
Director          | 1173|0.43|
President         |  951|0.35|
owner             |  923|0.34|
Engineer          |  881|0.33|
manager           |  827|0.31|
Operations Manager|  825|0.31|
teacher           |  803|0.30|
Vice President    |  790|0.29|

emp_length_norm|cnt  |pct  |
---------------+-----+-----+
10+ years      |88549|32.76|
< 1 year       |24652| 9.12|
2 years        |24036| 8.89|
3 years        |21452| 7.94|
n/a            |18745| 6.93|
1 year         |17722| 6.56|
5 years        |16665| 6.17|
4 years        |16207| 6.00|
6 years        |11870| 4.39|
7 years        |10823| 4.00|
8 years        |10533| 3.90|
9 years        | 9045| 3.35|

home_ownership_norm|cnt   |pct  |
-------------------+------+-----+
MORTGAGE           |133354|49.34|
RENT               |105663|39.09|
OWN                | 30927|11.44|
ANY                |   349| 0.13|
OTHER              |     4| 0.00|
NONE               |     2| 0.00|

verification_status_norm|cnt   |pct  |
------------------------+------+-----+
Source Verified         |105373|38.98|
Not Verified            | 97851|36.20|
Verified                | 67075|24.82|

zip_code_norm|cnt |pct |
-------------+----+----+
750xx        |2897|1.07|
945xx        |2809|1.04|
112xx        |2807|1.04|
606xx        |2465|0.91|
300xx        |2378|0.88|
331xx        |2333|0.86|
770xx        |2129|0.79|
070xx        |2126|0.79|
330xx        |2105|0.78|
891xx        |2082|0.77|
104xx        |2015|0.75|
900xx        |1975|0.73|
100xx        |1915|0.71|
117xx        |1897|0.70|
917xx        |1873|0.69|
852xx        |1716|0.63|
925xx        |1575|0.58|
334xx        |1527|0.56|
604xx        |1519|0.56|
913xx        |1519|0.56|

addr_state_norm|cnt  |pct  |
---------------+-----+-----+
CA             |37024|13.70|
TX             |22541| 8.34|
NY             |21854| 8.09|
FL             |19846| 7.34|
IL             |10845| 4.01|
NJ             | 9825| 3.63|
PA             | 9102| 3.37|
OH             | 9080| 3.36|
GA             | 8816| 3.26|
NC             | 7531| 2.79|
VA             | 7477| 2.77|
MI             | 7008| 2.59|
AZ             | 6516| 2.41|
MD             | 6312| 2.34|
MA             | 6117| 2.26|
CO             | 5732| 2.12|
WA             | 5495| 2.03|
MN             | 4782| 1.77|
IN             | 4604| 1.70|
TN             | 4417| 1.63|
```

> If you need top-N distribution for a text/categorical column, use `customer_set_top_20.sql`.

---

## 4) How to run (DBeaver)

1. Open `customer_profiling.sql`
2. Execute the whole script
3. You will get **two result sets**
   - **Text/Categorical scorecard**
   - **Numeric scorecard + statistics**

---

## 5) FA notes (quick interpretation)

- `emp_title` is free-text: most common is low (%), which is normal.
- `emp_length` and `home_ownership` are enums: most common can be high.
- `zip_code` is masked and naturally has low top1% due to wide distribution.
