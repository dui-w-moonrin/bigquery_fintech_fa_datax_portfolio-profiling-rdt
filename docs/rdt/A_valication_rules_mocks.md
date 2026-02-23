# Deliverable A — RDT‑lite Validation Rules (Mock)

**Repository:** `bigquery_fintech_fa_datax_portfolio-profiling-rdt`  
**Document version:** v0.1 (English)  
**Date:** 2026-02-20

> **Purpose**  
> Turn the existing profiling/scorecard work in this repo into an **RDT‑style validation ruleset**: clear IF/THEN rules, severity, and where the evidence lives (SQL scripts + artifacts).  
>  
> **Note**  
> This dataset is **fintech‑like / synthetic** and is **not** an official BOT RDT submission. This is a **RDT‑lite / mock** deliverable to demonstrate the regulatory data mindset and FA validation workflow.

---

## 0) Terminology

- **Entity**: A dataset with a clear grain (e.g., `raw.customers`, `raw.loans`)
- **Field**: A column in an entity
- **Rule**: A validation statement with a condition and an expected outcome (IF/THEN)
- **Evidence**: Where to reproduce the check (SQL) and where to inspect outcomes (CSV/MD artifacts)

### Severity
- **ERROR**: Not usable / breaks joins, reconciliation, or core reporting integrity
- **WARN**: Potentially usable but not standard or risky for reporting
- **INFO**: Monitoring metric, not necessarily “wrong”

### Scorecard metric definitions (repo‑wide)
- `missing` = NULL or blank after trim  
- `mismatched` = violates a locked rule / expected domain  
- `valid` = total − missing − mismatched  
- `unique` = number of distinct values  
- `most_common` = most frequent value + share  

---

## 1) Rule ID Convention (Mock)

- `VAL_CUST_###` — Customer / Counterparty‑like rules (`raw.customers`)
- `VAL_LOAN_###` — Loan / Credit account‑like rules (`raw.loans`)
- `VAL_REF_###` — Reference / Classification rules (code lists, geography ref)
- `VAL_XTBL_###` — Cross‑table integrity (FK‑like or join completeness)

---

## 2) Rule Catalog (Mock Validation Codes)

> **Important:** Evidence paths below are **placeholders** (recommended future file names).  
> When you implement, replace them with the actual SQL file paths in your repo, and export exception outputs to `artifacts/validation/`.

### 2.1 Customer / Counterparty‑like (`raw.customers`)

| Rule ID | Field(s) | IF (Condition) | THEN (Expected) | Severity | Evidence (SQL / Artifacts) |
|---|---|---|---|---|---|
| VAL_CUST_001 | customer_id | `customer_id` is NULL/blank | must be present | ERROR | `sql/20_validation/01_customers_rules.sql` + `exceptions__VAL_CUST_001.csv` |
| VAL_CUST_002 | customer_id | contains control chars / non‑printable | must not contain control chars | ERROR | same as above |
| VAL_CUST_003 | customer_id | duplicate `customer_id` | must be unique (PK) | ERROR | `sql/20_validation/01_customers_rules.sql` + `exceptions__VAL_CUST_003.csv` |
| VAL_CUST_010 | emp_title | value not normalized (leading/trailing spaces) | trim + empty→NULL | WARN | `docs/01_customers_profiling.md` |
| VAL_CUST_011 | home_ownership | value not in allowed set | must be one of allowed values | WARN | `docs/01_customers_profiling.md` |
| VAL_CUST_012 | annual_inc | `annual_inc` < 0 | must be ≥ 0 | ERROR | `sql/20_validation/01_customers_rules.sql` |
| VAL_CUST_013 | annual_inc | extreme outlier (e.g., > p99) | flag for review | INFO | `artifacts/validation/monitor__annual_inc_outliers.csv` |
| VAL_CUST_014 | dti | `dti` < 0 or `dti` > 100 (if percent) | must be within expected range | WARN | `sql/20_validation/01_customers_rules.sql` |
| VAL_CUST_015 | addr_state | missing/blank | should be present (if required) | WARN | `sql/20_validation/01_customers_rules.sql` |
| VAL_CUST_016 | addr_state | not 2‑letter uppercase code | must match regex `^[A-Z]2$` | WARN | `sql/20_validation/01_customers_rules.sql` |

### 2.2 Loan / Credit account‑like (`raw.loans`)

| Rule ID | Field(s) | IF (Condition) | THEN (Expected) | Severity | Evidence (SQL / Artifacts) |
|---|---|---|---|---|---|
| VAL_LOAN_001 | loan_id | `loan_id` is NULL/blank | must be present | ERROR | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_002 | loan_id | duplicate `loan_id` | must be unique (PK) | ERROR | `sql/20_validation/02_loans_rules.sql` + `exceptions__VAL_LOAN_002.csv` |
| VAL_LOAN_010 | customer_id | missing/blank | must be present | ERROR | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_011 | loan_status | value not in allowed set | must be allowed | ERROR | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_012 | term | value not in allowed set | should be allowed | WARN | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_013 | grade | value not in allowed set | should be allowed | WARN | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_014 | int_rate | < 0 or > 100 | must be within range | ERROR | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_015 | loan_amnt | ≤ 0 | must be > 0 | ERROR | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_016 | funded_amnt vs loan_amnt | funded amount > loan amount | should not exceed | WARN | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_017 | installment | ≤ 0 | must be > 0 | ERROR | `sql/20_validation/02_loans_rules.sql` |
| VAL_LOAN_018 | purpose | purpose not found in `raw.loan_purposes` | must exist in code list | ERROR | `sql/20_validation/04_cross_table_rules.sql` |

### 2.3 Reference / Classification

#### 2.3.1 Purpose code list (`raw.loan_purposes`)
| Rule ID | IF (Condition) | THEN (Expected) | Severity | Evidence |
|---|---|---|---|---|
| VAL_REF_001 | duplicate `purpose` | must be unique (PK) | ERROR | `sql/20_validation/03_reference_rules.sql` |
| VAL_REF_002 | `purpose` is NULL/blank | must be present | ERROR | `sql/20_validation/03_reference_rules.sql` |

#### 2.3.2 Geography reference (`raw.state_region`)
| Rule ID | IF (Condition) | THEN (Expected) | Severity | Evidence |
|---|---|---|---|---|
| VAL_REF_010 | duplicate `state` | must be unique (PK) | ERROR | `sql/20_validation/03_reference_rules.sql` |
| VAL_REF_011 | `region` or `subregion` is NULL/blank | should be present (or justified) | WARN | `docs/06_state_region.md` |
| VAL_REF_012 | `state` format invalid | must match `^[A-Z]2$` | WARN | `sql/20_validation/03_reference_rules.sql` |

### 2.4 Cross‑table Integrity (FK‑like / join completeness)

| Rule ID | IF (Condition) | THEN (Expected) | Severity | Evidence (SQL / Artifacts) |
|---|---|---|---|---|
| VAL_XTBL_001 | loans.customer_id not found in customers.customer_id | must exist (FK‑like) | ERROR | `sql/20_validation/04_cross_table_rules.sql` + `exceptions__VAL_XTBL_001.csv` |
| VAL_XTBL_002 | loans.purpose not found in loan_purposes.purpose | must exist | ERROR | `sql/20_validation/04_cross_table_rules.sql` + `exceptions__VAL_XTBL_002.csv` |
| VAL_XTBL_003 | customers.addr_state not found in state_region.state | should exist | WARN | `sql/20_validation/04_cross_table_rules.sql` |
| VAL_XTBL_010 | join‑enriched view has unexpected NULL region/subregion | investigate mapping gaps | INFO | `docs/05_loan_with_region.md` |

---

## 3) Known Gaps (Explicit Disclosure)

- No transaction/payment ledger → cannot do payment‑level reconciliation or delinquency aging
- No legal/customer identifiers → `customer_id` is a surrogate ID only
- Snapshot‑like dataset → limited month‑over‑month regulatory reporting simulation

