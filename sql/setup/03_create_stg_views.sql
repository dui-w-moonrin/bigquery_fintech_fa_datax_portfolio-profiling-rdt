-- 03_create_stg_views.sql (BigQuery Standard SQL)
-- Purpose: Create staging views to normalize RAW tables for consistent validation.
-- How to use:
-- 1) Ensure datasets exist: raw, stg (and optionally rep, artifacts).
-- 2) Run this script once.
-- 3) Run validation scripts under sql/20_validation/ against stg.* views.
--
-- NOTE: If your project/dataset names differ, replace:
--   raw.*  -> `your_project.your_raw_dataset.*`
--   stg.*  -> `your_project.your_stg_dataset.*`

-- =========================
-- Customers
-- =========================
CREATE OR REPLACE VIEW stg.v_customers AS
SELECT
  NULLIF(TRIM(CAST(customer_id AS STRING)), '')                           AS customer_id,
  NULLIF(TRIM(CAST(emp_title AS STRING)), '')                             AS emp_title,
  NULLIF(TRIM(CAST(emp_length AS STRING)), '')                            AS emp_length,
  NULLIF(TRIM(CAST(home_ownership AS STRING)), '')                        AS home_ownership,
  SAFE_CAST(annual_inc AS FLOAT64)                                        AS annual_inc,
  SAFE_CAST(annual_inc_joint AS FLOAT64)                                  AS annual_inc_joint,
  NULLIF(TRIM(CAST(verification_status AS STRING)), '')                   AS verification_status,
  NULLIF(TRIM(CAST(zip_code AS STRING)), '')                              AS zip_code,
  NULLIF(TRIM(UPPER(CAST(addr_state AS STRING))), '')                     AS addr_state,
  SAFE_CAST(avg_cur_bal AS FLOAT64)                                       AS avg_cur_bal,
  SAFE_CAST(Tot_cur_bal AS FLOAT64)                                       AS tot_cur_bal
FROM raw.customers;

-- =========================
-- Loans
-- =========================
CREATE OR REPLACE VIEW stg.v_loans AS
SELECT
  NULLIF(TRIM(CAST(loan_id AS STRING)), '')                               AS loan_id,
  NULLIF(TRIM(CAST(customer_id AS STRING)), '')                           AS customer_id,
  NULLIF(TRIM(CAST(loan_status AS STRING)), '')                           AS loan_status,
  SAFE_CAST(loan_amount AS FLOAT64)                                       AS loan_amount,
  NULLIF(TRIM(UPPER(CAST(state AS STRING))), '')                          AS state,
  SAFE_CAST(funded_amount AS FLOAT64)                                     AS funded_amount,
  NULLIF(TRIM(CAST(term AS STRING)), '')                                  AS term,
  SAFE_CAST(int_rate AS FLOAT64)                                          AS int_rate,
  SAFE_CAST(installment AS FLOAT64)                                       AS installment,
  NULLIF(TRIM(CAST(grade AS STRING)), '')                                 AS grade,
  NULLIF(TRIM(CAST(issue_d AS STRING)), '')                               AS issue_d,
  -- Keep issue_date as STRING (source might vary). If it's a proper DATE already, SAFE_CAST will preserve.
  SAFE_CAST(issue_date AS DATE)                                           AS issue_date,
  SAFE_CAST(issue_year AS INT64)                                          AS issue_year,
  NULLIF(TRIM(CAST(pymnt_plan AS STRING)), '')                            AS pymnt_plan,
  NULLIF(TRIM(CAST(type AS STRING)), '')                                  AS type,
  NULLIF(TRIM(CAST(purpose AS STRING)), '')                               AS purpose,
  NULLIF(TRIM(CAST(description AS STRING)), '')                           AS description,
  NULLIF(TRIM(CAST(notes AS STRING)), '')                                 AS notes
FROM raw.loans;

-- =========================
-- Reference: loan purposes (code list)
-- =========================
CREATE OR REPLACE VIEW stg.v_loan_purposes AS
SELECT
  NULLIF(TRIM(CAST(purpose AS STRING)), '') AS purpose
FROM raw.loan_purposes;

-- =========================
-- Reference: state -> region mapping
-- =========================
CREATE OR REPLACE VIEW stg.v_state_region AS
SELECT
  NULLIF(TRIM(UPPER(CAST(state AS STRING))), '')      AS state,
  NULLIF(TRIM(CAST(subregion AS STRING)), '')         AS subregion,
  NULLIF(TRIM(CAST(region AS STRING)), '')            AS region
FROM raw.state_region;
