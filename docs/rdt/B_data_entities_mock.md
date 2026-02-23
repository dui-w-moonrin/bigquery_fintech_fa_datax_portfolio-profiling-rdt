# Deliverable B — RDT-lite Data Entities (DER-like) (Mock)

**Repository:** `bigquery_fintech_fa_datax_portfolio-profiling-rdt`  
**Document version:** v0.2 (English)  
**Date:** 2026-02-23

> **What’s new in v0.2**  
> Added **Data Entity Overview** tables in an RDT-like format (Data Type / Format / Req. / Check Dup.), inspired by BOT RDT DataEntities documentation.

---

## 1) Entity Inventory (High-level)

| DER-like ID | Source (table/view) | Business meaning | Grain | Primary Key (expected) |
|---|---|---|---|---|
| DER_CUST | `raw.customers` / `stg.v_customers` | Customer / counterparty-like master data | 1 row per `customer_id` | `customer_id` |
| DER_LOAN | `raw.loans` / `stg.v_loans` | Loan / credit-account-like snapshot | 1 row per `loan_id` | `loan_id` |
| DER_PURPOSE_REF | `raw.loan_purposes` / `stg.v_loan_purposes` | Purpose code list (classification) | 1 row per `purpose` | `purpose` |
| DER_GEO_REF | `raw.state_region` / `stg.v_state_region` | State → subregion/region mapping (reference) | 1 row per `state` | `state` |

**Legend**
- **Req.**: M = Mandatory, O = Optional (in this RDT-lite mock)
- **Check Dup.**: Y = duplicates should be checked (key-like)

---

## 2) DER_CUST — Customer / Counterparty-like

**Description:** Customer master dataset used as a counterparty-like entity (surrogate ID).  
**Grain:** 1 row per `customer_id`  
**PK (expected):** `customer_id`

### Data Entity Overview — Customer / Counterparty-like (DER_CUST)

| No | Data Element | Check Dup. | Req. | Data Type | Format | Validation (Mock) | Classification |
|---:|---|:---:|:---:|---|---|---|---|
| 1 | customer_id | Y | M | String | varchar(40) | VAL_CUST_001 (missing), VAL_CUST_003 (dup) | Identifier |
| 2 | emp_title | N | O | String | varchar(200) | Hygiene (trim/blank→NULL) | Attribute |
| 3 | emp_length | N | O | String | varchar(20) | Enum hygiene (optional) | Attribute |
| 4 | home_ownership | N | O | String | varchar(40) | Enum hygiene (optional) | Classification |
| 5 | annual_inc | N | O | Numeric | numeric(18,2) | VAL_CUST_012 (>=0) | Measure |
| 6 | annual_inc_joint | N | O | Numeric | numeric(18,2) | Non-negative (optional) | Measure |
| 7 | verification_status | N | O | String | varchar(40) | VAL_CUST_020 (missing monitor) | Classification |
| 8 | zip_code | N | O | String | varchar(10) | Format hygiene (optional) | Code |
| 9 | addr_state | N | O | String | char(2) | VAL_CUST_015/016 + VAL_XTBL_003 | Geography |
| 10 | avg_cur_bal | N | O | Numeric | numeric(18,2) | Non-negative (optional) | Measure |
| 11 | tot_cur_bal | N | O | Numeric | numeric(18,2) | Non-negative (optional) | Measure |


---

## 3) DER_LOAN — Loan / Credit-account-like

**Description:** Loan snapshot dataset used as a credit-account-like entity.  
**Grain:** 1 row per `loan_id`  
**PK (expected):** `loan_id`  
**FK-like:** `customer_id` → `DER_CUST.customer_id`

### Data Entity Overview — Loan / Credit-account-like (DER_LOAN)

| No | Data Element | Check Dup. | Req. | Data Type | Format | Validation (Mock) | Classification |
|---:|---|:---:|:---:|---|---|---|---|
| 1 | loan_id | Y | M | String | varchar(40) | VAL_LOAN_001 (missing), VAL_LOAN_002 (dup) | Identifier |
| 2 | customer_id | N | M | String | varchar(40) | VAL_LOAN_010 + VAL_XTBL_001 | Identifier |
| 3 | loan_status | N | M | String | varchar(60) | Domain set (future), completeness | Classification |
| 4 | loan_amount | N | M | Numeric | numeric(18,2) | VAL_LOAN_015 (>0) | Measure |
| 5 | state | N | O | String | char(2) | VAL_XTBL_004 (ref) | Geography |
| 6 | funded_amount | N | O | Numeric | numeric(18,2) | VAL_LOAN_016 (<= loan_amount) | Measure |
| 7 | term | N | O | String | varchar(20) | Domain hygiene (optional) | Classification |
| 8 | int_rate | N | O | Numeric | numeric(10,4) | VAL_LOAN_014 (0..100) | Measure |
| 9 | installment | N | M | Numeric | numeric(18,2) | VAL_LOAN_017 (>0) | Measure |
| 10 | grade | N | O | String | varchar(10) | Domain hygiene (optional) | Classification |
| 11 | issue_d | N | O | String | varchar(40) | Hygiene (optional) | Date/Time |
| 12 | issue_date | N | O | Date | date | Safe parsing in STG | Date/Time |
| 13 | issue_year | N | O | Integer | int | VAL_LOAN_030 (missing monitor) | Date/Time |
| 14 | pymnt_plan | N | O | String | varchar(10) | Domain hygiene (optional) | Classification |
| 15 | type | N | O | String | varchar(40) | Domain hygiene (optional) | Classification |
| 16 | purpose | N | O | String | varchar(80) | VAL_XTBL_002 (ref) | Classification |
| 17 | description | N | O | String | text | Free text (no strict validation) | Free text |
| 18 | notes | N | O | String | text | Free text (no strict validation) | Free text |


---

## 4) DER_PURPOSE_REF — Purpose code list (Classification)

**Description:** Controlled vocabulary for `loans.purpose`.  
**Grain:** 1 row per `purpose`  
**PK (expected):** `purpose`

### Data Entity Overview — Purpose code list (DER_PURPOSE_REF)

| No | Data Element | Check Dup. | Req. | Data Type | Format | Validation (Mock) | Classification |
|---:|---|:---:|:---:|---|---|---|---|
| 1 | purpose | Y | M | String | varchar(80) | VAL_REF_002 (missing), VAL_REF_001 (dup) | Classification |


---

## 5) DER_GEO_REF — Geography reference (State → Region)

**Description:** Reference mapping for geography enrichment and validation.  
**Grain:** 1 row per `state`  
**PK (expected):** `state`

### Data Entity Overview — Geography reference (DER_GEO_REF)

| No | Data Element | Check Dup. | Req. | Data Type | Format | Validation (Mock) | Classification |
|---:|---|:---:|:---:|---|---|---|---|
| 1 | state | Y | M | String | char(2) | VAL_REF_012 (regex), VAL_REF_010 (dup) | Geography |
| 2 | subregion | N | O | String | varchar(60) | VAL_REF_011 (missing) | Geography |
| 3 | region | N | O | String | varchar(40) | VAL_REF_011 (missing) | Geography |


---

## 6) Known gaps (Explicit Disclosure)
- No payment/transaction ledger → cannot define payment-level entities or reconciliations  
- No official identifiers → `customer_id` is surrogate only  
- Snapshot-like structure → limited month-over-month regulatory simulation  

---

