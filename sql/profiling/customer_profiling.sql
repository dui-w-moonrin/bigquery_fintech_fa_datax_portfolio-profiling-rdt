-- Customer Profiling Scorecard (raw.customers)
-- Definitions: missing = NULL/blank (trimmed), mismatched = violates locked rule, valid = total - missing - mismatched

WITH base AS (
  SELECT
    NULLIF(BTRIM(customer_id::text), '') AS customer_id_norm,
    NULLIF(BTRIM(emp_title::text), '')   AS emp_title_norm
  FROM raw.customers
),

-- 1) customer_id : LOCK mismatched = contains control chars ([[:cntrl:]])
score_customer_id AS (
  WITH agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE customer_id_norm IS NULL) AS missing_cnt,
      COUNT(*) FILTER (
        WHERE customer_id_norm IS NOT NULL
          AND customer_id_norm ~ '[[:cntrl:]]'
      ) AS mismatched_cnt,
      COUNT(DISTINCT customer_id_norm) FILTER (WHERE customer_id_norm IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE customer_id_norm IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  mc AS (
    SELECT customer_id_norm AS most_common_value, COUNT(*) AS most_common_cnt
    FROM base
    WHERE customer_id_norm IS NOT NULL
    GROUP BY customer_id_norm
    ORDER BY COUNT(*) DESC, customer_id_norm
    LIMIT 1
  )
  SELECT
    'customer_id' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value

  FROM agg a
  LEFT JOIN mc ON TRUE
),

-- emp_title (required for scorecard): Missing = NULL/blank
-- mismatched = 0 (free-text, v1 ไม่ enforce)
score_emp_title AS (
  -- LOCK missing = NULL/blank; mismatched = none (free-text v1)
  WITH agg AS (
    SELECT
      COUNT(*) AS total_rows,

      COUNT(*) FILTER (WHERE emp_title_norm IS NULL) AS missing_cnt,

      0::bigint AS mismatched_cnt,

      COUNT(DISTINCT emp_title_norm) FILTER (WHERE emp_title_norm IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE emp_title_norm IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  mc AS (
    SELECT emp_title_norm AS most_common_value, COUNT(*) AS most_common_cnt
    FROM base
    WHERE emp_title_norm IS NOT NULL
    GROUP BY emp_title_norm
    ORDER BY COUNT(*) DESC, emp_title_norm
    LIMIT 1
  )
  SELECT
    'emp_title' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
),

score_emp_length AS (
  -- LOCK missing = NULL/blank or normalized to 'n/a'; mismatched = not in allowed set
  WITH norm AS (
    SELECT
      NULLIF(LOWER(BTRIM(emp_length::text)), '') AS v
    FROM raw.customers
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,

      -- Missing: null/blank OR n/a (missing disguised)
      COUNT(*) FILTER (
        WHERE v IS NULL
           OR v IN ('n/a', 'na', 'not available')
      ) AS missing_cnt,

      -- Mismatched: มีค่าแล้ว แต่ไม่อยู่ใน allowed set
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v NOT IN ('n/a', 'na', 'not available')
          AND NOT (
            v = '10+ years'
            OR v = '< 1 year'
            OR v ~* '^[1-9]\s+year(s)?$'   -- 1 year .. 9 years
          )
      ) AS mismatched_cnt,

      COUNT(DISTINCT v) FILTER (
        WHERE v IS NOT NULL
          AND v NOT IN ('n/a', 'na', 'not available')
      ) AS unique_cnt,

      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v NOT IN ('n/a', 'na', 'not available')
      ) AS non_missing_cnt
    FROM norm
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM norm
    WHERE v IS NOT NULL
      AND v NOT IN ('n/a', 'na', 'not available')
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'emp_length' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value

  FROM agg a
  LEFT JOIN mc ON TRUE
),
score_home_ownership AS (
  -- LOCK mismatched = not in allowed set (MORTGAGE/RENT/OWN/ANY/OTHER/NONE)
  WITH norm AS (
    SELECT
      NULLIF(UPPER(BTRIM(home_ownership::text)), '') AS v
    FROM raw.customers
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,

      -- Missing: NULL/blank
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,

      -- Mismatched: มีค่าแล้วแต่ไม่อยู่ใน allowed set
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v NOT IN ('MORTGAGE','RENT','OWN','ANY','OTHER','NONE')
      ) AS mismatched_cnt,

      -- Unique among non-missing (จะออกมา <= 6)
      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM norm
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM norm
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'home_ownership' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
),
score_verification_status AS (
  -- LOCK mismatched = not in allowed set (Source Verified/Not Verified/Verified)
  WITH norm AS (
    SELECT
      NULLIF(LOWER(BTRIM(verification_status::text)), '') AS v
    FROM raw.customers
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,

      -- Missing: NULL/blank
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,

      -- Mismatched: มีค่าแล้วแต่ไม่อยู่ใน allowed set
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v NOT IN ('source verified', 'not verified', 'verified')
      ) AS mismatched_cnt,

      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM norm
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM norm
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'verification_status' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
),
score_zip_code AS (
  -- LOCK mismatched = not match pattern ^[0-9]{3}xx$
  WITH norm AS (
    SELECT
      NULLIF(BTRIM(zip_code::text), '') AS v
    FROM raw.customers
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,

      -- Missing: NULL/blank
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,

      -- Mismatched: ไม่เข้า pattern 3 digit + 'xx'
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v !~ '^[0-9]{3}xx$'
      ) AS mismatched_cnt,

      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM norm
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM norm
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'zip_code' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
),
score_addr_state AS (
  -- LOCK mismatched = not match pattern ^[A-Z]{2}$
  WITH norm AS (
    SELECT
      NULLIF(UPPER(BTRIM(addr_state::text)), '') AS v
    FROM raw.customers
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,

      -- Missing: NULL/blank
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,

      -- Mismatched: ไม่ใช่ 2 ตัวอักษร A-Z
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v !~ '^[A-Z]{2}$'
      ) AS mismatched_cnt,

      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM norm
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM norm
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'addr_state' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
)

-- Result set B: numeric scorecard + stats (rounded)
SELECT
  t.column_name,
  t.total_rows,
  t.valid_cnt, t.valid_pct,
  t.mismatched_cnt, t.mismatched_pct,
  t.missing_cnt, t.missing_pct,
  t.unique_cnt, t.unique_pct,
  t.most_common_cnt, t.most_common_pct,
  t.most_common_value
FROM (
  SELECT 1 AS sort_order, * FROM score_customer_id
  UNION ALL
  SELECT 2 AS sort_order, * FROM score_emp_title
  UNION ALL
  SELECT 3 AS sort_order, * FROM score_emp_length
  UNION ALL
  SELECT 4 AS sort_order, * FROM score_home_ownership
  UNION ALL
  SELECT 5 AS sort_order, * FROM score_verification_status
  UNION ALL
  SELECT 6 AS sort_order, * FROM score_zip_code
  UNION ALL
  SELECT 7 AS sort_order, * FROM score_addr_state
) t
ORDER BY t.sort_order;

WITH base AS (
  SELECT
    annual_inc::text        AS annual_inc_raw,
    annual_inc_joint::text  AS annual_inc_joint_raw,
    avg_cur_bal::text       AS avg_cur_bal_raw
  FROM raw.customers
),

/* ---------------------------
   1) annual_inc
---------------------------- */
score_annual_inc AS (
  -- LOCK mismatched = cannot parse numeric after removing commas/$
  WITH norm AS (
    SELECT
      NULLIF(BTRIM(annual_inc_raw), '') AS raw_val,
      -- normalize: remove commas and $ then trim
      NULLIF(BTRIM(REPLACE(REPLACE(annual_inc_raw, ',', ''), '$', '')), '') AS norm_val
    FROM base
  ),
  typed AS (
    SELECT
      raw_val,
      norm_val,
      CASE
        WHEN norm_val IS NULL THEN NULL
        WHEN norm_val ~ '^[+-]?\d+(\.\d+)?$' THEN norm_val::numeric
        ELSE NULL
      END AS num_val,
      CASE
        WHEN norm_val IS NULL THEN 'MISSING'
        WHEN norm_val ~ '^[+-]?\d+(\.\d+)?$' THEN 'PARSED'
        ELSE 'MISMATCHED'
      END AS parse_status
    FROM norm
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE parse_status = 'MISSING') AS missing_cnt,
      COUNT(*) FILTER (WHERE parse_status = 'MISMATCHED') AS mismatched_cnt,
      COUNT(*) FILTER (WHERE parse_status = 'PARSED') AS parsed_cnt
    FROM typed
  ),
  stats AS (
    SELECT
      AVG(num_val)                          AS mean,
      STDDEV_SAMP(num_val)                  AS std,
      MIN(num_val)                          AS min,
      PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY num_val) AS p25,
      PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY num_val) AS p50,
      PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY num_val) AS p75,
      MAX(num_val)                          AS max
    FROM typed
    WHERE parse_status = 'PARSED'
  )
  SELECT
    'annual_inc' AS column_name,
    a.total_rows,

    -- valid = parsed (ตอนนี้ยังไม่ทำ out-of-range; ถ้าจะเพิ่มค่อยขยาย)
    a.parsed_cnt AS valid_cnt,
    ROUND(100.0 * a.parsed_cnt / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    s.mean, s.std, s.min, s.p25, s.p50, s.p75, s.max
  FROM agg a
  CROSS JOIN stats s
),

/* ---------------------------
   2) annual_inc_joint
---------------------------- */
score_annual_inc_joint AS (
  -- LOCK missing = NULL/blank; mismatched = cannot parse numeric after removing commas/$
  WITH norm AS (
    SELECT
      NULLIF(BTRIM(annual_inc_joint_raw), '') AS raw_val,
      NULLIF(BTRIM(REPLACE(REPLACE(annual_inc_joint_raw, ',', ''), '$', '')), '') AS norm_val
    FROM base
  ),
  typed AS (
    SELECT
      raw_val,
      norm_val,
      CASE
        WHEN norm_val IS NULL THEN NULL
        WHEN norm_val ~ '^[+-]?\d+(\.\d+)?$' THEN norm_val::numeric
        ELSE NULL
      END AS num_val,
      CASE
        WHEN norm_val IS NULL THEN 'MISSING'
        WHEN norm_val ~ '^[+-]?\d+(\.\d+)?$' THEN 'PARSED'
        ELSE 'MISMATCHED'
      END AS parse_status
    FROM norm
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE parse_status = 'MISSING') AS missing_cnt,
      COUNT(*) FILTER (WHERE parse_status = 'MISMATCHED') AS mismatched_cnt,
      COUNT(*) FILTER (WHERE parse_status = 'PARSED') AS parsed_cnt
    FROM typed
  ),
  stats AS (
    SELECT
      AVG(num_val)                          AS mean,
      STDDEV_SAMP(num_val)                  AS std,
      MIN(num_val)                          AS min,
      PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY num_val) AS p25,
      PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY num_val) AS p50,
      PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY num_val) AS p75,
      MAX(num_val)                          AS max
    FROM typed
    WHERE parse_status = 'PARSED'
  )
  SELECT
    'annual_inc_joint' AS column_name,
    a.total_rows,

    a.parsed_cnt AS valid_cnt,
    ROUND(100.0 * a.parsed_cnt / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    s.mean, s.std, s.min, s.p25, s.p50, s.p75, s.max
  FROM agg a
  CROSS JOIN stats s
),

/* ---------------------------
   3) avg_cur_bal
---------------------------- */
score_avg_cur_bal AS (
  -- LOCK missing = NULL/blank; mismatched = cannot parse numeric after removing commas/$
  WITH norm AS (
    SELECT
      NULLIF(BTRIM(avg_cur_bal_raw), '') AS raw_val,
      NULLIF(BTRIM(REPLACE(REPLACE(avg_cur_bal_raw, ',', ''), '$', '')), '') AS norm_val
    FROM base
  ),
  typed AS (
    SELECT
      raw_val,
      norm_val,
      CASE
        WHEN norm_val IS NULL THEN NULL
        WHEN norm_val ~ '^[+-]?\d+(\.\d+)?$' THEN norm_val::numeric
        ELSE NULL
      END AS num_val,
      CASE
        WHEN norm_val IS NULL THEN 'MISSING'
        WHEN norm_val ~ '^[+-]?\d+(\.\d+)?$' THEN 'PARSED'
        ELSE 'MISMATCHED'
      END AS parse_status
    FROM norm
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE parse_status = 'MISSING') AS missing_cnt,
      COUNT(*) FILTER (WHERE parse_status = 'MISMATCHED') AS mismatched_cnt,
      COUNT(*) FILTER (WHERE parse_status = 'PARSED') AS parsed_cnt
    FROM typed
  ),
  stats AS (
    SELECT
      AVG(num_val)                          AS mean,
      STDDEV_SAMP(num_val)                  AS std,
      MIN(num_val)                          AS min,
      PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY num_val) AS p25,
      PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY num_val) AS p50,
      PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY num_val) AS p75,
      MAX(num_val)                          AS max
    FROM typed
    WHERE parse_status = 'PARSED'
  )
  SELECT
    'avg_cur_bal' AS column_name,
    a.total_rows,

    a.parsed_cnt AS valid_cnt,
    ROUND(100.0 * a.parsed_cnt / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    s.mean, s.std, s.min, s.p25, s.p50, s.p75, s.max
  FROM agg a
  CROSS JOIN stats s
)

SELECT
  t.column_name,
  t.total_rows,
  t.valid_cnt, t.valid_pct,
  t.mismatched_cnt, t.mismatched_pct,
  t.missing_cnt, t.missing_pct,

  ROUND(t.mean::numeric, 2) AS mean,
  ROUND(t.std::numeric,  2) AS std,
  ROUND(t.min::numeric,  2) AS min,
  ROUND(t.p25::numeric,  2) AS p25,
  ROUND(t.p50::numeric,  2) AS p50,
  ROUND(t.p75::numeric,  2) AS p75,
  ROUND(t.max::numeric,  2) AS max

FROM (
  SELECT 1 AS sort_order, * FROM score_annual_inc
  UNION ALL
  SELECT 2 AS sort_order, * FROM score_annual_inc_joint
  UNION ALL
  SELECT 3 AS sort_order, * FROM score_avg_cur_bal
) t
ORDER BY t.sort_order;