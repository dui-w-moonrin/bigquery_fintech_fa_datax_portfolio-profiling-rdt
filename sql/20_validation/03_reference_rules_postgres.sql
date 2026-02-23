-- 03_reference_rules_postgres.sql (PostgreSQL)
-- Output: validation summary rows for reference tables
-- Sources: stg.v_loan_purposes, stg.v_state_region

WITH
p AS (SELECT * FROM stg.v_loan_purposes),
r AS (SELECT * FROM stg.v_state_region),
p_total AS (SELECT COUNT(*)::bigint AS total_rows FROM p),
r_total AS (SELECT COUNT(*)::bigint AS total_rows FROM r),
p_dupes AS (
  SELECT purpose, COUNT(*) AS cnt
  FROM p
  WHERE purpose IS NOT NULL
  GROUP BY purpose
  HAVING COUNT(*) > 1
),
r_dupes AS (
  SELECT state, COUNT(*) AS cnt
  FROM r
  WHERE state IS NOT NULL
  GROUP BY state
  HAVING COUNT(*) > 1
)

-- VAL_REF_001: duplicate purpose in code list
SELECT
  'VAL_REF_001'::text AS rule_id,
  'ERROR'::text       AS severity,
  pt.total_rows,
  (SELECT COALESCE(SUM(cnt),0) FROM p_dupes)::bigint AS fail_cnt,
  (SELECT COALESCE(SUM(cnt),0)::numeric FROM p_dupes) / NULLIF(pt.total_rows::numeric, 0) AS fail_pct
FROM p_total pt

UNION ALL
-- VAL_REF_002: purpose missing/blank
SELECT
  'VAL_REF_002'::text AS rule_id,
  'ERROR'::text       AS severity,
  pt.total_rows,
  (SELECT COUNT(*) FROM p WHERE purpose IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM p WHERE purpose IS NULL) / NULLIF(pt.total_rows::numeric, 0) AS fail_pct
FROM p_total pt

UNION ALL
-- VAL_REF_010: duplicate state in state_region
SELECT
  'VAL_REF_010'::text AS rule_id,
  'ERROR'::text       AS severity,
  rt.total_rows,
  (SELECT COALESCE(SUM(cnt),0) FROM r_dupes)::bigint AS fail_cnt,
  (SELECT COALESCE(SUM(cnt),0)::numeric FROM r_dupes) / NULLIF(rt.total_rows::numeric, 0) AS fail_pct
FROM r_total rt

UNION ALL
-- VAL_REF_011: region/subregion missing
SELECT
  'VAL_REF_011'::text AS rule_id,
  'WARN'::text        AS severity,
  rt.total_rows,
  (SELECT COUNT(*) FROM r WHERE region IS NULL OR subregion IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM r WHERE region IS NULL OR subregion IS NULL) / NULLIF(rt.total_rows::numeric, 0) AS fail_pct
FROM r_total rt

UNION ALL
-- VAL_REF_012: state format invalid
SELECT
  'VAL_REF_012'::text AS rule_id,
  'WARN'::text        AS severity,
  rt.total_rows,
  (SELECT COUNT(*) FROM r WHERE state IS NOT NULL AND state !~ '^[A-Z]{2}$')::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM r WHERE state IS NOT NULL AND state !~ '^[A-Z]{2}$') / NULLIF(rt.total_rows::numeric, 0) AS fail_pct
FROM r_total rt;

-- Optional exceptions:
--   SELECT * FROM stg.v_state_region WHERE region IS NULL OR subregion IS NULL LIMIT 100;
