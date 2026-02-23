-- 01_customers_rules_postgres.sql (PostgreSQL)
-- Output: validation summary rows (rule_id, severity, total_rows, fail_cnt, fail_pct)
-- Source: stg.v_customers
--
-- Notes:
-- - This script returns a result set with multiple rows (one per rule) via UNION ALL.
-- - fail_pct uses NULLIF to avoid division by zero.

WITH base AS (
  SELECT *
  FROM stg.v_customers
),
total AS (
  SELECT COUNT(*)::bigint AS total_rows FROM base
),
dupes AS (
  SELECT customer_id, COUNT(*) AS cnt
  FROM base
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING COUNT(*) > 1
)
-- VAL_CUST_001: customer_id missing
SELECT
  'VAL_CUST_001'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE customer_id IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE customer_id IS NULL) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_CUST_003: duplicate customer_id (PK dupes)
SELECT
  'VAL_CUST_003'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COALESCE(SUM(cnt),0) FROM dupes)::bigint AS fail_cnt,
  (SELECT COALESCE(SUM(cnt),0)::numeric FROM dupes) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_CUST_012: annual_inc negative
SELECT
  'VAL_CUST_012'::text AS rule_id,
  'ERROR'::text        AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE annual_inc IS NOT NULL AND annual_inc < 0)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE annual_inc IS NOT NULL AND annual_inc < 0) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_CUST_015: addr_state missing
SELECT
  'VAL_CUST_015'::text AS rule_id,
  'WARN'::text         AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE addr_state IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE addr_state IS NULL) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_CUST_016: addr_state format invalid (expect 2 uppercase letters)
SELECT
  'VAL_CUST_016'::text AS rule_id,
  'WARN'::text         AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE addr_state IS NOT NULL AND addr_state !~ '^[A-Z]{2}$')::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE addr_state IS NOT NULL AND addr_state !~ '^[A-Z]{2}$') / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t

UNION ALL
-- VAL_CUST_020: verification_status missing (hygiene/monitor)
SELECT
  'VAL_CUST_020'::text AS rule_id,
  'INFO'::text         AS severity,
  t.total_rows,
  (SELECT COUNT(*) FROM base WHERE verification_status IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM base WHERE verification_status IS NULL) / NULLIF(t.total_rows::numeric, 0) AS fail_pct
FROM total t;

-- Optional exceptions examples:
-- 1) Missing customer_id:
--   SELECT * FROM stg.v_customers WHERE customer_id IS NULL LIMIT 100;
-- 2) Duplicate customer_id list:
--   SELECT customer_id, COUNT(*) AS cnt
--   FROM stg.v_customers
--   WHERE customer_id IS NOT NULL
--   GROUP BY customer_id
--   HAVING COUNT(*) > 1
--   ORDER BY cnt DESC, customer_id
--   LIMIT 100;
