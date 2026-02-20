/* =====================================================================
   File    : query_set_top_20.sql
   Purpose : Data profiling / scorecard query for (edit column / any table)
   Output  : One row per checked column (or distribution helper), with
             counts for total / missing / mismatched / valid / unique / mode.
   Notes   : missing = NULL or blank after trimming
             mismatched = violates the locked rule described per section
   Updated : 2026-02-20 (sql refactoring: consistent comments & layout)
===================================================================== */

-- Top-N(20) distribution helper for raw.customers (edit column in SELECT/GROUP BY)
-- Tip: run this when you want to inspect values before locking an allowed-set or pattern.

SELECT
  NULLIF(BTRIM(column::text), '') AS value_norm,  -- <-- change this column
  COUNT(*) AS cnt,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM raw.customers
WHERE NULLIF(BTRIM(column::text), '') IS NOT NULL  -- <-- keep aligned with column
GROUP BY 1
ORDER BY cnt DESC, value_norm -- <-- keep aligned this column
LIMIT 20;

/* example sql:
SELECT
  NULLIF(BTRIM(emp_title::text), '') AS emp_title_norm,
  COUNT(*) AS cnt,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM raw.customers
WHERE NULLIF(BTRIM(emp_length::text), '') IS NOT NULL
GROUP BY 1
ORDER BY cnt DESC, emp_title_norm
LIMIT 20;
*/