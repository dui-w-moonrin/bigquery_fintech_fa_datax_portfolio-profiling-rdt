# Dataset Overview

**Repo:** `bigquery_fintech_fa_datax_portfolio-profiling-rdt`  
**Updated (refactor):** 2026-02-20

---

## Purpose
This repo mirrors the public **BigQuery** dataset `cloud-training-demos.fintech` into **PostgreSQL** so we can run:
- Column-level **profiling scorecards**
- Simple **validation / reconciliation** checks (FA-friendly)
- “RDT-ish” documentation patterns (clear definitions + auditable rules)

## Source
- **BigQuery public dataset:** `cloud-training-demos.fintech`
- **Dataset page (Kaggle mirror):** `mustafakeser4/bigquery-fintech-dataset`

> Notes
> - This is a **training dataset**.  
> - We do not “fix” raw data in the profiling layer; we **detect, document, and recommend** handling for downstream layers.

## Tables in scope
| Table | Role | Typical grain |
|---|---|---|
| `raw.customers` | Customer attributes (mostly categorical + some numeric) | 1 row per customer (in this dataset it behaves like 1 row per `customer_id`) |
| `raw.loans` | Core loan records | 1 row per `loan_id` |
| `raw.loan_count_by_year` | Aggregated series | 1 row per `issue_year` |
| `raw.loan_purposes` | Domain list (enum reference) | 1 row per `purpose` |
| `raw.loan_with_region` | Enriched loans (region attached) | 1 row per `loan_id` |
| `raw.state_region` | State → subregion → region mapping | 1 row per `state` |

## What “RDT-ish” means here
We model a lightweight, auditable approach similar in spirit to regulated data work:
- Consistent **definitions**: `valid / missing / mismatched`
- Locked **allowed sets** for enums (when appropriate)
- Locked **patterns** for codes/IDs
- Numeric parsing + basic sanity rules (`> 0`, reasonable ranges)
- Outputs that can be exported as a **scorecard CSV**

## Repo artifacts (high-level)
- SQL scripts generate scorecards / checks (see `/sql`)
- Markdown files are the **human-readable reports** (see `/docs`)

Key docs in this pack:
- `01_customers_profiling.md`
- `02_loans_profiling.md`
- `03_loan_count_by_year.md`
- `04_loan_purposes.md`
- `05_loan_with_region_profiling.md`
- `06_state_region.md`
