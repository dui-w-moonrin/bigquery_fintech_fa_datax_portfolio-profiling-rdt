# Deliverable C — RDT-lite Reporting Guidelines (Mock)

**Repository:** `bigquery_fintech_fa_datax_portfolio-profiling-rdt`  
**Document version:** v0.2 (English)  
**Effective date:** 2026-02-23  
**Owner:** Portfolio (Functional Analyst / Data Quality)  
**Status:** Draft (RDT-lite / mock)

---

## Document Information
- **Audience:** Hiring managers / reviewers for Functional Analyst (Data / RDT mindset) roles
- **Objective:** Provide RDT-style guidance for interpreting and validating a fintech-like dataset using a reproducible SQL validation pack.
- **In-scope entities:** Customers, Loans, Purpose code list, State/Region reference
- **Out-of-scope:** Payment ledger, delinquency aging, official identifiers (bank-grade IDs)


## Table of Contents
1. Scope & Principles  
2. Validation Dimensions (CN / CM / RI)  
3. Global Data Standards  
4. Entity Guidelines  
   4.1 Customers (DER_CUST) — Field Cards  
   4.2 Loans (DER_LOAN) — Field Cards  
   4.3 Reference Tables — Field Cards  
5. Evidence Links  

---

## 1) Scope & Principles

### 1.1 Scope
Covered entities:
- Customers: `raw.customers`, `stg.v_customers`
- Loans: `raw.loans`, `stg.v_loans`
- Reference:
  - Purposes: `raw.loan_purposes`, `stg.v_loan_purposes`
  - Geography: `raw.state_region`, `stg.v_state_region`

Not covered (dataset limitations):
- Transaction/payment ledger and payment-level reconciliation
- Delinquency aging / repayment schedules / interest accrual detail
- Official identifiers (national ID, account number)

### 1.2 Principles
1) **Consistency** — shared definitions and normalization rules across all entities  
2) **Auditability** — every rule is reproducible via SQL and inspectable via outputs  
3) **Minimal transformation** — keep RAW as-is; normalize in STG views  
4) **Explicit gaps** — do not fabricate values; document limitations

---

## 2) Validation Dimensions (RDT-style)

This guideline organizes rules using three RDT-like dimensions:

- **CM — Completeness**: required fields present (missing checks)
- **CN — Consistency**: values and relationships are logically consistent (ranges, cross-field checks)
- **RI — Referential Integrity**: references resolve (FK-like orphan checks)

**Examples in this repo (mock codes):**
- CM: `VAL_CUST_001`, `VAL_LOAN_001`, `VAL_LOAN_010`
- CN: `VAL_LOAN_014`, `VAL_LOAN_016`, `VAL_LOAN_015`
- RI: `VAL_XTBL_001`, `VAL_XTBL_002`, `VAL_XTBL_003`, `VAL_XTBL_004`

---

## 3) Global Data Standards (Repo-wide)

### 3.1 Missing definition
A value is **missing** if it is NULL or blank after trimming.

- **Text:** `NULLIF(TRIM(col::text), '') IS NULL`
- **Numeric:** NULL is missing (do not treat 0 as missing unless explicitly defined)

### 3.2 Normalization rules (STG layer)
In `stg.v_*` apply:
- Trim spaces, convert empty string to NULL
- Standardize code fields to uppercase where appropriate (`state`, `addr_state`)
- Cast numeric fields to `numeric` (invalid casts should surface as NULL where feasible)

### 3.3 Date standardization (important)
`issue_date` may appear as:
- `YYYY-MM-DD` (direct date), or
- `Month YYYY` (e.g., “June 2013”)

STG performs safe parsing:
- `YYYY-MM-DD` → cast directly  
- `Month YYYY` → parsed with `to_date(..., 'FMMonth YYYY')` (first day of month)  
- unparseable → NULL (monitor via validation)

---

## 4) Entity Guidelines + Field Cards

# 4.1 Customers — DER_CUST (`stg.v_customers`)

### [customer_id]
- **Definition:** Surrogate customer identifier (counterparty-like)
- **Req.:** Mandatory  
- **Data type / format:** String, `varchar(40)`  
- **Normalization:** trim; blank → NULL
- **Validation dimension:** **CM + RI**
- **Validation (mock codes):**
  - CM: `VAL_CUST_001` (missing)
  - CN: `VAL_CUST_003` (duplicate PK)
- **Notes:** No official identifier in source; treat as surrogate only.

### [addr_state]
- **Definition:** Customer address state code
- **Req.:** Optional (recommended)
- **Data type / format:** String, `char(2)`
- **Normalization:** uppercase; blank → NULL
- **Validation dimension:** **CM + RI**
- **Validation (mock codes):**
  - CM: `VAL_CUST_015` (missing monitor)
  - CN: `VAL_CUST_016` (regex `^[A-Z]{2}$`)
  - RI: `VAL_XTBL_003` (must exist in `state_region.state`, WARN if orphan)
- **Notes:** Do not fabricate unknown state codes.

### [annual_inc]
- **Definition:** Annual income indicator
- **Req.:** Optional
- **Data type / format:** Numeric, `numeric(18,2)`
- **Normalization:** cast to numeric; invalid → NULL
- **Validation dimension:** **CN**
- **Validation (mock codes):**
  - CN: `VAL_CUST_012` (non-negative)
- **Notes:** Outliers should be flagged as INFO (optional future rule).

---

# 4.2 Loans — DER_LOAN (`stg.v_loans`)

### [loan_id]
- **Definition:** Loan identifier
- **Req.:** Mandatory
- **Data type / format:** String, `varchar(40)`
- **Normalization:** trim; blank → NULL
- **Validation dimension:** **CM**
- **Validation (mock codes):**
  - CM: `VAL_LOAN_001` (missing)
  - CN: `VAL_LOAN_002` (duplicate PK)

### [customer_id]
- **Definition:** Borrower identifier linking loans to customers
- **Req.:** Mandatory
- **Data type / format:** String, `varchar(40)`
- **Normalization:** trim; blank → NULL
- **Validation dimension:** **CM + RI**
- **Validation (mock codes):**
  - CM: `VAL_LOAN_010` (missing)
  - RI: `VAL_XTBL_001` (loan→customer orphan, ERROR)

### [loan_amount]
- **Definition:** Loan principal amount
- **Req.:** Mandatory
- **Data type / format:** Numeric, `numeric(18,2)`
- **Normalization:** cast to numeric; invalid → NULL
- **Validation dimension:** **CN**
- **Validation (mock codes):**
  - CN: `VAL_LOAN_015` (must be > 0)

### [funded_amount]
- **Definition:** Funded amount associated with the loan
- **Req.:** Optional
- **Data type / format:** Numeric, `numeric(18,2)`
- **Normalization:** cast to numeric; invalid → NULL
- **Validation dimension:** **CN**
- **Validation (mock codes):**
  - CN: `VAL_LOAN_016` (should not exceed `loan_amount`, WARN)

### [int_rate]
- **Definition:** Interest rate indicator
- **Req.:** Optional
- **Data type / format:** Numeric, `numeric(10,4)`
- **Normalization:** cast to numeric; invalid → NULL
- **Validation dimension:** **CN**
- **Validation (mock codes):**
  - CN: `VAL_LOAN_014` (range 0..100)

### [purpose]
- **Definition:** Loan purpose category
- **Req.:** Optional (recommended)
- **Data type / format:** String, `varchar(80)`
- **Normalization:** trim; blank → NULL
- **Validation dimension:** **RI**
- **Validation (mock codes):**
  - RI: `VAL_XTBL_002` (loan→purpose orphan, ERROR)

### [issue_date]
- **Definition:** Loan origination date (parsed)
- **Req.:** Optional
- **Data type / format:** Date, `date`
- **Normalization:** safe parsing (supports `YYYY-MM-DD` and `Month YYYY`)
- **Validation dimension:** **CM (monitor)**
- **Validation (mock codes):**
  - CM: `VAL_LOAN_030` (missing `issue_year` monitor; add parse-fail monitor as future enhancement)
- **Notes:** Unparseable values become NULL (do not crash pipeline).

---

# 4.3 Reference Tables (Classification / Geography)

### Purpose code list — [purpose] (`stg.v_loan_purposes`)
- **Req.:** Mandatory
- **Data type / format:** String, `varchar(80)`
- **Validation dimension:** **CM + CN**
- **Validation (mock codes):**
  - CM: `VAL_REF_002` (missing)
  - CN: `VAL_REF_001` (duplicate key)

### Geography ref — [state] (`stg.v_state_region`)
- **Req.:** Mandatory
- **Data type / format:** String, `char(2)`
- **Validation dimension:** **CN**
- **Validation (mock codes):**
  - CN: `VAL_REF_012` (regex `^[A-Z]{2}$`)
  - CN: `VAL_REF_010` (duplicate key)
  - CM: `VAL_REF_011` (region/subregion missing, WARN)

---