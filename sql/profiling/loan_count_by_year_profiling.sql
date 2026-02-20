/* =====================================================================
   File    : loan_count_by_year_profiling.sql
   Purpose : Data profiling / scorecard query for raw.loan_count_by_year
   Output  : One row per checked column (or distribution helper), with
             counts for total / missing / mismatched / valid / unique / mode.
   Notes   : missing = NULL or blank after trimming
             mismatched = violates the locked rule described per section
   Updated : 2026-02-20 (sql refactoring: consistent comments & layout)
===================================================================== */

WITH
-- [CTE] norm: normalize raw columns (trim/NULLify/cast)
norm AS (
  SELECT
    issue_year::numeric AS issue_year_raw,
    CASE
      WHEN issue_year IS NULL THEN NULL
      ELSE issue_year::numeric::int
    END AS issue_year,
    loan_count::bigint AS loan_count
  FROM raw.loan_count_by_year
),
-- [CTE] score_issue_year: scorecard metrics for one column
score_issue_year AS (
  SELECT
    'issue_year' AS column_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
      WHERE issue_year_raw IS NOT NULL
        AND issue_year_raw = FLOOR(issue_year_raw)
        AND issue_year BETWEEN 1900 AND 2100
    ) AS valid_cnt,
    COUNT(*) FILTER (
      WHERE issue_year_raw IS NOT NULL
        AND (
          issue_year_raw <> FLOOR(issue_year_raw)
          OR issue_year < 1900 OR issue_year > 2100
        )
    ) AS mismatched_cnt,
    COUNT(*) FILTER (WHERE issue_year_raw IS NULL) AS missing_cnt
  FROM norm
),
-- [CTE] score_loan_count: scorecard metrics for one column
score_loan_count AS (
  SELECT
    'loan_count' AS column_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE loan_count IS NOT NULL AND loan_count > 0) AS valid_cnt,
    COUNT(*) FILTER (WHERE loan_count IS NOT NULL AND loan_count <= 0) AS mismatched_cnt,
    COUNT(*) FILTER (WHERE loan_count IS NULL) AS missing_cnt
  FROM norm
)
SELECT
  s.column_name,
  s.total_rows,
  s.valid_cnt,
  ROUND(100.0 * s.valid_cnt / NULLIF(s.total_rows, 0), 2) AS valid_pct,
  s.mismatched_cnt,
  ROUND(100.0 * s.mismatched_cnt / NULLIF(s.total_rows, 0), 2) AS mismatched_pct,
  s.missing_cnt,
  ROUND(100.0 * s.missing_cnt / NULLIF(s.total_rows, 0), 2) AS missing_pct
FROM (
  SELECT * FROM score_issue_year
  UNION ALL
  SELECT * FROM score_loan_count
) s
ORDER BY s.column_name;

WITH norm AS (
  SELECT issue_year::numeric::int AS issue_year, loan_count::bigint AS loan_count
  FROM raw.loan_count_by_year
  WHERE issue_year IS NOT NULL
)
SELECT issue_year, COUNT(*) AS row_cnt
FROM norm
GROUP BY issue_year
HAVING COUNT(*) > 1
ORDER BY issue_year;

WITH norm AS (
  SELECT issue_year::numeric::int AS issue_year, loan_count::bigint AS loan_count
  FROM raw.loan_count_by_year
  WHERE issue_year IS NOT NULL
),
-- [CTE] bounds: CTE
bounds AS (
  SELECT MIN(issue_year) AS min_year, MAX(issue_year) AS max_year
  FROM norm
),
-- [CTE] years: CTE
years AS (
  SELECT generate_series(min_year, max_year)::int AS issue_year
  FROM bounds
)
SELECT
  y.issue_year,
  CASE WHEN n.issue_year IS NULL THEN 1 ELSE 0 END AS missing_year_flag
FROM years y
LEFT JOIN norm n USING (issue_year)
WHERE n.issue_year IS NULL
ORDER BY y.issue_year;

WITH norm AS (
  SELECT issue_year::numeric::int AS issue_year, loan_count::bigint AS loan_count
  FROM raw.loan_count_by_year
)
SELECT
  COUNT(*) AS year_rows,
  MIN(issue_year) AS min_year,
  MAX(issue_year) AS max_year,
  SUM(loan_count) AS total_loans,
  MIN(loan_count) AS min_loan_count,
  MAX(loan_count) AS max_loan_count
FROM norm;