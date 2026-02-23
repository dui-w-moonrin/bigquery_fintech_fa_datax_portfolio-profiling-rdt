## Scope

This repository demonstrates **two deliverables** for a fintech-like dataset in a Functional Analyst (FA) style:

**A) Data Profiling (SQL-first)**  
A reproducible SQL profiling/validation pack (completeness, duplicates, domain checks, and FK-like integrity) with evidence-ready documentation.

**B) RDT-like Documentation (Mocked)**  
A set of regulator-style documents (RDT-lite) to showcase a regulatory data transformation mindset:
- **A:** Validation Rules (Mock)  
- **B:** Data Entities (DER-like Overview)  
- **C:** Reporting Guidelines (RDT-lite)

---

## Quick links

### Phase A — Profiling evidence
- Dataset overview: `docs/profiling/00_about_dataset.md`
- Customers scorecard: `docs/profiling/01_customers_profiling.md`
- Loans scorecard: `docs/profiling/02_loans_profiling.md`
- Loan count by year: `docs/profiling/03_loan_count_by_year.md`
- Loan purposes reference: `docs/profiling/04_loan_purposes.md`
- Loan with region (enriched): `docs/profiling/05_loan_with_region_profiling.md`
- State → Subregion → Region mapping: `docs/profiling/06_state_region.md`

### Phase B — RDT-like (Mocked) docs
- A) Validation Rules (Mock): `docs/rdt/A_*.md`
- B) Data Entities (DER-like): `docs/rdt/B_*.md`
- C) Reporting Guidelines: `docs/rdt/C_*.md`

---

## ERD (Entity Relationship Diagram)

This ERD captures the **minimum join paths** and the **derived/reporting layer** tables used in this repo.
Key points:
- `CUSTOMER` → `LOAN` is treated as **joinable via `customer_id`** (dataset behaves like 1:1 per customer in this training set)
- `STATE_REGION` enriches loans from `state` to reporting `region`
- `DIM_PURPOSE` is a reference list to validate and standardize `purpose`
- `LOAN_WITH_REGION` and `LOAN_COUNT_BY_YEAR` are **derived/reporting** assets built from `LOAN`

```mermaid
erDiagram

  %% =========================
  %% CORE LAYER (source-aligned / normalized-ish)
  %% =========================
  CUSTOMER ||--|| LOAN : "customer_id (1:1 in dataset)"
  STATE_REGION ||--o{ LOAN : "state -> region (1:many)"

  %% Optional DIM (derived but behaves like dimension)
  DIM_PURPOSE ||--o{ LOAN : "purpose (1:many)"

  %% =========================
  %% DERIVED / REPORTING LAYER
  %% =========================
  LOAN ||--|| LOAN_WITH_REGION : "enrich region via state_region"
  LOAN ||--o{ LOAN_COUNT_BY_YEAR : "aggregate by issue_year"

  %% =========================
  %% TABLE DEFINITIONS
  %% =========================
  CUSTOMER {
    string customer_id PK
    string emp_title
    string emp_length
    string home_ownership
    number annual_inc
    number annual_inc_joint
    string verification_status
    string zip_code
    string addr_state
    number avg_cur_bal
    number tot_cur_bal
  }

  LOAN {
    string loan_id PK
    string customer_id FK
    string loan_status
    number loan_amount
    string state FK
    number funded_amount
    string term
    number int_rate
    number installment
    string grade
    string issue_d
    date issue_date
    int issue_year
    string pymnt_plan
    string type
    string purpose FK
    string description
    string notes
  }

  STATE_REGION {
    string state PK
    string subregion
    string region
  }

  DIM_PURPOSE {
    string purpose PK
  }

  LOAN_WITH_REGION {
    string loan_id PK,FK
    number loan_amount
    string region
  }

  LOAN_COUNT_BY_YEAR {
    int issue_year PK
    int loan_count
  }
```

---


