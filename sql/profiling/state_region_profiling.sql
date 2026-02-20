WITH base AS (
  SELECT
    NULLIF(BTRIM(state), '')     AS state_trim,
    NULLIF(BTRIM(subregion), '') AS subregion_trim,
    NULLIF(BTRIM(region), '')    AS region_trim,

    UPPER(NULLIF(BTRIM(state), '')) AS state_norm,
    NULLIF(BTRIM(subregion), '')    AS subregion_norm, -- keep original case (already nice)
    INITCAP(NULLIF(BTRIM(region), '')) AS region_norm
  FROM raw.state_region
),

-- 1) state score
score_state AS (
  WITH agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE state_trim IS NULL) AS missing_cnt,

      -- mismatched: not 2-letter A-Z code OR header-like values
      COUNT(*) FILTER (
        WHERE state_trim IS NOT NULL
          AND (
            state_norm !~ '^[A-Z]{2}$'
            OR state_norm IN ('STATE')  -- header leak guard
          )
      ) AS bad_format_cnt,

      COUNT(DISTINCT state_norm) FILTER (WHERE state_trim IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE state_trim IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  most_common AS (
    SELECT
      state_norm AS most_common_value,
      COUNT(*) AS most_common_cnt
    FROM base
    WHERE state_trim IS NOT NULL
    GROUP BY state_norm
    ORDER BY COUNT(*) DESC, state_norm
    LIMIT 1
  )
  SELECT
    'state' AS column_name,
    a.total_rows,

    -- duplicates among non-missing (for reference table, this should be 0)
    (a.non_missing_cnt - a.unique_cnt) AS dup_cnt,

    -- mismatched = bad_format + duplicates
    (a.bad_format_cnt + (a.non_missing_cnt - a.unique_cnt)) AS mismatched_cnt,
    ROUND(100.0 * (a.bad_format_cnt + (a.non_missing_cnt - a.unique_cnt)) / NULLIF(a.total_rows,0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows,0), 2) AS missing_pct,

    -- valid
    (a.total_rows - a.missing_cnt - (a.bad_format_cnt + (a.non_missing_cnt - a.unique_cnt))) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - (a.bad_format_cnt + (a.non_missing_cnt - a.unique_cnt))) / NULLIF(a.total_rows,0), 2) AS valid_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt,0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.non_missing_cnt,0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN most_common mc ON TRUE
),

-- 2) subregion score
score_subregion AS (
  WITH agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE subregion_trim IS NULL) AS missing_cnt,

      -- mismatched: not in allowed subregions OR header-like value "subregion"
      COUNT(*) FILTER (
        WHERE subregion_trim IS NOT NULL
          AND (
            subregion_norm NOT IN (
              'New England','Middle Atlantic',
              'East North Central','West North Central',
              'South Atlantic','East South Central','West South Central',
              'Mountain','Pacific'
            )
            OR LOWER(subregion_norm) = 'subregion'
          )
      ) AS mismatched_cnt,

      COUNT(*) FILTER (
        WHERE subregion_trim IS NOT NULL
          AND subregion_norm IN (
            'New England','Middle Atlantic',
            'East North Central','West North Central',
            'South Atlantic','East South Central','West South Central',
            'Mountain','Pacific'
          )
      ) AS valid_cnt,

      COUNT(DISTINCT subregion_norm) FILTER (WHERE subregion_trim IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE subregion_trim IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  most_common AS (
    SELECT
      subregion_norm AS most_common_value,
      COUNT(*) AS most_common_cnt
    FROM base
    WHERE subregion_trim IS NOT NULL
    GROUP BY subregion_norm
    ORDER BY COUNT(*) DESC, subregion_norm
    LIMIT 1
  )
  SELECT
    'subregion' AS column_name,
    a.total_rows,
    NULL::bigint AS dup_cnt,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows,0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows,0), 2) AS missing_pct,

    a.valid_cnt,
    ROUND(100.0 * a.valid_cnt / NULLIF(a.total_rows,0), 2) AS valid_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt,0), 2) AS unique_pct,

    mc.most_common_cnt,
    ROUND(100.0 * mc.most_common_cnt / NULLIF(a.non_missing_cnt,0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN most_common mc ON TRUE
),

-- 3) region score
score_region AS (
  WITH agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE region_trim IS NULL) AS missing_cnt,

      -- mismatched: not in allowed regions OR header-like value "region"
      COUNT(*) FILTER (
        WHERE region_trim IS NOT NULL
          AND (
            region_norm NOT IN ('Northeast','Midwest','South','West')
            OR LOWER(region_trim) = 'region'
          )
      ) AS mismatched_cnt,

      COUNT(*) FILTER (
        WHERE region_trim IS NOT NULL
          AND region_norm IN ('Northeast','Midwest','South','West')
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
    NULL::bigint AS dup_cnt,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows,0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows,0), 2) AS missing_pct,

    a.valid_cnt,
    ROUND(100.0 * a.valid_cnt / NULLIF(a.total_rows,0), 2) AS valid_pct,

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
  SELECT 1 AS sort_order, * FROM score_state
  UNION ALL
  SELECT 2 AS sort_order, * FROM score_subregion
  UNION ALL
  SELECT 3 AS sort_order, * FROM score_region
) t
ORDER BY t.sort_order;

WITH base AS (
  SELECT
    UPPER(NULLIF(BTRIM(state), '')) AS state_norm,
    NULLIF(BTRIM(subregion), '')    AS subregion_norm,
    INITCAP(NULLIF(BTRIM(region), '')) AS region_norm
  FROM raw.state_region
)
SELECT
  subregion_norm,
  region_norm,
  COUNT(*) AS cnt
FROM base
WHERE subregion_norm IS NOT NULL
  AND region_norm IS NOT NULL
GROUP BY subregion_norm, region_norm
HAVING NOT (
  (subregion_norm IN ('New England','Middle Atlantic') AND region_norm = 'Northeast')
  OR (subregion_norm IN ('East North Central','West North Central') AND region_norm = 'Midwest')
  OR (subregion_norm IN ('South Atlantic','East South Central','West South Central') AND region_norm = 'South')
  OR (subregion_norm IN ('Mountain','Pacific') AND region_norm = 'West')
)
ORDER BY cnt DESC, subregion_norm, region_norm;