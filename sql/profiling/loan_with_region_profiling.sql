WITH
-- 1) score: loan_id (int4) -> text-style scorecard
score_loan_id AS (
  WITH base AS (
    SELECT loan_id
    FROM raw.loan_with_region
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE loan_id IS NULL) AS missing_cnt,
      COUNT(*) FILTER (WHERE loan_id IS NOT NULL AND loan_id <= 0) AS bad_range_cnt,
      COUNT(DISTINCT loan_id) FILTER (WHERE loan_id IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE loan_id IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  most_common AS (
    SELECT
      loan_id::text AS most_common_value,
      COUNT(*) AS most_common_cnt
    FROM base
    WHERE loan_id IS NOT NULL
    GROUP BY loan_id
    ORDER BY COUNT(*) DESC, loan_id
    LIMIT 1
  )
  SELECT
    'loan_id' AS column_name,
    a.total_rows,

    -- duplicates among non-missing
    (a.non_missing_cnt - a.unique_cnt) AS dup_cnt,

    -- valid / mismatched / missing (ให้รวมกันได้เหมือน region)
    (a.total_rows - a.missing_cnt - (a.bad_range_cnt + (a.non_missing_cnt - a.unique_cnt))) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - (a.bad_range_cnt + (a.non_missing_cnt - a.unique_cnt))) / NULLIF(a.total_rows,0), 2) AS valid_pct,

    (a.bad_range_cnt + (a.non_missing_cnt - a.unique_cnt)) AS mismatched_cnt,
    ROUND(100.0 * (a.bad_range_cnt + (a.non_missing_cnt - a.unique_cnt)) / NULLIF(a.total_rows,0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows,0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt,0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.non_missing_cnt,0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN most_common mc ON TRUE
),

-- 2) score: region (varchar) -> text-style scorecard
score_region AS (
  WITH base AS (
    SELECT
      region,
      NULLIF(BTRIM(region), '') AS region_trim,
      INITCAP(NULLIF(BTRIM(region), '')) AS region_norm
    FROM raw.loan_with_region
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE region_trim IS NULL) AS missing_cnt,
      COUNT(*) FILTER (
        WHERE region_trim IS NOT NULL
          AND region_norm NOT IN ('South','West','Northeast','Midwest')
      ) AS mismatched_cnt,
      COUNT(*) FILTER (
        WHERE region_trim IS NOT NULL
          AND region_norm IN ('South','West','Northeast','Midwest')
      ) AS valid_cnt,
      COUNT(DISTINCT region_norm) FILTER (WHERE region_trim IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE region_trim IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  most_common AS (
    SELECT
      region_norm AS most_common_value,
      COUNT(*) AS most_common_cnt
    FROM base
    WHERE region_trim IS NOT NULL
    GROUP BY region_norm
    ORDER BY COUNT(*) DESC, region_norm
    LIMIT 1
  )
  SELECT
    'region' AS column_name,
    a.total_rows,

    -- สำหรับ text enum เราไม่สน dup_cnt แบบเดียวกับ id (ปล่อยเป็น NULL ได้)
    NULL::bigint AS dup_cnt,

    a.valid_cnt,
    ROUND(100.0 * a.valid_cnt / NULLIF(a.total_rows,0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows,0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows,0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt,0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.non_missing_cnt,0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN most_common mc ON TRUE
)

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
  SELECT 1 AS sort_order, * FROM score_loan_id
  UNION ALL
  SELECT 2 AS sort_order, * FROM score_region
) t
ORDER BY t.sort_order;


WITH base AS (
  SELECT loan_amount::numeric AS loan_amount
  FROM raw.loan_with_region
),
agg AS (
  SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE loan_amount IS NULL) AS missing_cnt,
    COUNT(*) FILTER (WHERE loan_amount IS NOT NULL AND loan_amount <= 0) AS mismatched_cnt,
    COUNT(*) FILTER (WHERE loan_amount IS NOT NULL AND loan_amount > 0) AS valid_cnt
  FROM base
),
stats AS (
  SELECT
    AVG(loan_amount) AS mean,
    STDDEV_SAMP(loan_amount) AS std,
    MIN(loan_amount) AS min,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY loan_amount) AS p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY loan_amount) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY loan_amount) AS p75,
    MAX(loan_amount) AS max
  FROM base
  WHERE loan_amount IS NOT NULL
)
SELECT
  'loan_amount' AS column_name,
  a.total_rows,
  a.valid_cnt,
  ROUND(100.0 * a.valid_cnt / NULLIF(a.total_rows,0), 2) AS valid_pct,
  a.mismatched_cnt,
  ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows,0), 2) AS mismatched_pct,
  a.missing_cnt,
  ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows,0), 2) AS missing_pct,
  -- numeric summary (rounded)
  ROUND(s.mean::numeric, 2) AS mean,
  ROUND(s.std::numeric, 2) AS std,
  ROUND(s.min::numeric, 2) AS min,
  ROUND(s.p25::numeric, 2) AS p25,
  ROUND(s.p50::numeric, 2) AS p50,
  ROUND(s.p75::numeric, 2) AS p75,
  ROUND(s.max::numeric, 2) AS max
FROM agg a
CROSS JOIN stats s;

WITH a AS (
  SELECT COUNT(*) AS cnt, COUNT(DISTINCT loan_id) AS distinct_loan_id
  FROM raw.loan_with_region
),
b AS (
  SELECT COUNT(*) AS cnt, COUNT(DISTINCT loan_id) AS distinct_loan_id
  FROM raw.loans
)
SELECT
  a.cnt AS loan_with_region_rows,
  a.distinct_loan_id AS loan_with_region_distinct_loan_id,
  b.cnt AS loans_rows,
  b.distinct_loan_id AS loans_distinct_loan_id
FROM a CROSS JOIN b;