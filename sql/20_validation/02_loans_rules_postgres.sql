-- 02_loans_rules_postgres.sql (PostgreSQL)
-- Output: validation summary rows (rule_id, severity, total_rows, fail_cnt, fail_pct)
-- Source: stg.v_loans

WITH base AS (
  SELECT * FROM stg.v_loans
),
total AS (
  SELECT COUNT(*)::bigint AS total_rows FROM base
),
dupes AS (
  SELECT loan_id, COUNT(*) AS cnt
  FROM base
  WHERE loan_id IS NOT NULL
  GROUP BY loan_id
  HAVING COUNT(*) > 1
)
-- VAL_LOAN_001: loan_id missing
SELECT
  'VAL_LOAN_001'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE loan_id IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE loan_id IS NULL) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_LOAN_002: duplicate loan_id (PK dupes)
SELECT
  'VAL_LOAN_002'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COALESCE(SUM(cnt),0) FROM dupes)::bigint AS fail_cnt,
  (SELECT COALESCE(SUM(cnt),0)::numeric FROM dupes) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_LOAN_010: customer_id missing in loans
SELECT
  'VAL_LOAN_010'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE customer_id IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE customer_id IS NULL) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_LOAN_014: int_rate out of range (0..100)
SELECT
  'VAL_LOAN_014'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE int_rate IS NOT NULL AND (int_rate < 0 OR int_rate > 100))::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE int_rate IS NOT NULL AND (int_rate < 0 OR int_rate > 100)) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_LOAN_015: loan_amount must be > 0 (or not null)
SELECT
  'VAL_LOAN_015'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE loan_amount IS NULL OR loan_amount <= 0)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE loan_amount IS NULL OR loan_amount <= 0) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_LOAN_017: installment must be > 0 (or not null)
SELECT
  'VAL_LOAN_017'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE installment IS NULL OR installment <= 0)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE installment IS NULL OR installment <= 0) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_LOAN_016: funded_amount should not exceed loan_amount (warn)
SELECT
  'VAL_LOAN_016'::text AS rule_id,
  'WARN'::text         AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE funded_amount IS NOT NULL AND loan_amount IS NOT NULL AND funded_amount > loan_amount)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE funded_amount IS NOT NULL AND loan_amount IS NOT NULL AND funded_amount > loan_amount) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_LOAN_030: issue_year missing (monitor)
SELECT
  'VAL_LOAN_030'::text AS rule_id,
  'INFO'::text         AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE issue_year IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE issue_year IS NULL) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t;

-- Optional exceptions examples:
--   SELECT * FROM stg.v_loans WHERE loan_amount IS NULL OR loan_amount <= 0 LIMIT 100;
