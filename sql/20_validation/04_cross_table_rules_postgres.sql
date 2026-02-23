-- 04_cross_table_rules_postgres.sql (PostgreSQL)
-- Output: Cross-table integrity checks (FK-like orphans, mapping coverage)
-- Sources: stg.v_loans, stg.v_customers, stg.v_loan_purposes, stg.v_state_region

WITH
l AS (SELECT loan_id, customer_id, purpose, state FROM stg.v_loans),
c AS (SELECT customer_id, addr_state FROM stg.v_customers),
p AS (SELECT purpose FROM stg.v_loan_purposes),
r AS (SELECT state FROM stg.v_state_region),

-- total denominators (we use counts of the driving table rows)
t_loans AS (SELECT COUNT(*)::bigint AS total_rows FROM l),
t_cust  AS (SELECT COUNT(*)::bigint AS total_rows FROM c)

-- VAL_XTBL_001: loans.customer_id must exist in customers.customer_id
SELECT
  'VAL_XTBL_001'::text AS rule_id,
  'ERROR'::text        AS severity,
  tl.total_rows,
  (SELECT COUNT(*) FROM l LEFT JOIN c ON l.customer_id = c.customer_id
    WHERE l.customer_id IS NOT NULL AND c.customer_id IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM l LEFT JOIN c ON l.customer_id = c.customer_id
    WHERE l.customer_id IS NOT NULL AND c.customer_id IS NULL) / NULLIF(tl.total_rows::numeric, 0) AS fail_pct
FROM t_loans tl

UNION ALL
-- VAL_XTBL_002: loans.purpose must exist in purpose code list
SELECT
  'VAL_XTBL_002'::text AS rule_id,
  'ERROR'::text        AS severity,
  tl.total_rows,
  (SELECT COUNT(*) FROM l LEFT JOIN p ON l.purpose = p.purpose
    WHERE l.purpose IS NOT NULL AND p.purpose IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM l LEFT JOIN p ON l.purpose = p.purpose
    WHERE l.purpose IS NOT NULL AND p.purpose IS NULL) / NULLIF(tl.total_rows::numeric, 0) AS fail_pct
FROM t_loans tl

UNION ALL
-- VAL_XTBL_003: customers.addr_state should exist in state_region.state
SELECT
  'VAL_XTBL_003'::text AS rule_id,
  'WARN'::text         AS severity,
  tc.total_rows,
  (SELECT COUNT(*) FROM c LEFT JOIN r ON c.addr_state = r.state
    WHERE c.addr_state IS NOT NULL AND r.state IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM c LEFT JOIN r ON c.addr_state = r.state
    WHERE c.addr_state IS NOT NULL AND r.state IS NULL) / NULLIF(tc.total_rows::numeric, 0) AS fail_pct
FROM t_cust tc

UNION ALL
-- VAL_XTBL_004: loans.state should exist in state_region.state
SELECT
  'VAL_XTBL_004'::text AS rule_id,
  'WARN'::text         AS severity,
  tl.total_rows,
  (SELECT COUNT(*) FROM l LEFT JOIN r ON l.state = r.state
    WHERE l.state IS NOT NULL AND r.state IS NULL)::bigint AS fail_cnt,
  (SELECT COUNT(*)::numeric FROM l LEFT JOIN r ON l.state = r.state
    WHERE l.state IS NOT NULL AND r.state IS NULL) / NULLIF(tl.total_rows::numeric, 0) AS fail_pct
FROM t_loans tl;

-- Optional exceptions:
--   SELECT l.loan_id, l.customer_id
--   FROM l LEFT JOIN c ON l.customer_id = c.customer_id
--   WHERE l.customer_id IS NOT NULL AND c.customer_id IS NULL
--   LIMIT 100;
