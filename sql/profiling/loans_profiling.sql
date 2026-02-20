WITH
/* =========================
   1) loan_id (PK-style)
   LOCK:
     missing     = loan_id IS NULL
     mismatched  = (loan_id <= 0) OR duplicate among non-missing
========================= */
score_loan_id AS (
  WITH base AS (
    SELECT loan_id
    FROM raw.loans
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
  mc AS (
    SELECT loan_id::text AS most_common_value, COUNT(*) AS most_common_cnt
    FROM base
    WHERE loan_id IS NOT NULL
    GROUP BY loan_id
    ORDER BY COUNT(*) DESC, loan_id
    LIMIT 1
  ),
  final AS (
    SELECT
      'loan_id' AS column_name,
      a.total_rows,
      a.missing_cnt,
      (a.non_missing_cnt - a.unique_cnt) AS dup_cnt,
      a.bad_range_cnt,
      a.unique_cnt,
      a.non_missing_cnt,
      COALESCE(m.most_common_cnt, 0) AS most_common_cnt,
      m.most_common_value
    FROM agg a
    LEFT JOIN mc m ON TRUE
  )
  SELECT
    column_name,
    total_rows,

    -- valid
    (total_rows - missing_cnt - (bad_range_cnt + dup_cnt)) AS valid_cnt,
    ROUND(100.0 * (total_rows - missing_cnt - (bad_range_cnt + dup_cnt)) / NULLIF(total_rows, 0), 2) AS valid_pct,

    -- mismatched
    (bad_range_cnt + dup_cnt) AS mismatched_cnt,
    ROUND(100.0 * (bad_range_cnt + dup_cnt) / NULLIF(total_rows, 0), 2) AS mismatched_pct,

    -- missing
    missing_cnt,
    ROUND(100.0 * missing_cnt / NULLIF(total_rows, 0), 2) AS missing_pct,

    -- unique
    unique_cnt,
    ROUND(100.0 * unique_cnt / NULLIF(non_missing_cnt, 0), 2) AS unique_pct,

    -- most common
    most_common_cnt,
    ROUND(100.0 * most_common_cnt / NULLIF(total_rows, 0), 2) AS most_common_pct,
    most_common_value
  FROM final
),

/* =========================
   2) customer_id (in loans) - ID text
   LOCK:
     missing     = NULL/blank (trimmed)
     mismatched  = has control chars
========================= */
score_customer_id AS (
  WITH base AS (
    SELECT NULLIF(BTRIM(customer_id::text), '') AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND v ~ '[[:cntrl:]]') AS mismatched_cnt,
      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM base
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
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

    COALESCE(mc.most_common_cnt, 0) AS most_common_cnt,
    ROUND(100.0 * COALESCE(mc.most_common_cnt, 0) / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
),

/* =========================
   3) loan_status (enum)
   LOCK:
     missing     = NULL/blank
     mismatched  = not in allowed set
========================= */
score_loan_status AS (
  WITH base AS (
    SELECT NULLIF(BTRIM(loan_status::text), '') AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v NOT IN (
            'Current',
            'Fully Paid',
            'Charged Off',
            'Late (31-120 days)',
            'In Grace Period',
            'Late (16-30 days)',
            'Default'
          )
      ) AS mismatched_cnt,
      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM base
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'loan_status' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    COALESCE(mc.most_common_cnt, 0) AS most_common_cnt,
    ROUND(100.0 * COALESCE(mc.most_common_cnt, 0) / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
),
score_state AS (
  WITH base AS (
    SELECT NULLIF(BTRIM(state::text), '') AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v !~ '^[A-Z]{2}$'
      ) AS mismatched_cnt,
      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM base
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'state' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    COALESCE(mc.most_common_cnt, 0) AS most_common_cnt,
    ROUND(100.0 * COALESCE(mc.most_common_cnt, 0) / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
),
score_term AS (
  WITH base AS (
    SELECT NULLIF(BTRIM(term::text), '') AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v NOT IN ('36 months', '60 months')
      ) AS mismatched_cnt,
      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM base
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'term' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    COALESCE(mc.most_common_cnt, 0) AS most_common_cnt,
    ROUND(100.0 * COALESCE(mc.most_common_cnt, 0) / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
),
score_grade AS (
  WITH base AS (
    SELECT NULLIF(BTRIM(grade::text), '') AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (
        WHERE v IS NOT NULL
          AND v NOT IN ('A','B','C','D','E','F','G')
      ) AS mismatched_cnt,
      COUNT(DISTINCT v) FILTER (WHERE v IS NOT NULL) AS unique_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL) AS non_missing_cnt
    FROM base
  ),
  mc AS (
    SELECT v AS most_common_value, COUNT(*) AS most_common_cnt
    FROM base
    WHERE v IS NOT NULL
    GROUP BY v
    ORDER BY COUNT(*) DESC, v
    LIMIT 1
  )
  SELECT
    'grade' AS column_name,
    a.total_rows,

    (a.total_rows - a.missing_cnt - a.mismatched_cnt) AS valid_cnt,
    ROUND(100.0 * (a.total_rows - a.missing_cnt - a.mismatched_cnt) / NULLIF(a.total_rows, 0), 2) AS valid_pct,

    a.mismatched_cnt,
    ROUND(100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0), 2) AS mismatched_pct,

    a.missing_cnt,
    ROUND(100.0 * a.missing_cnt / NULLIF(a.total_rows, 0), 2) AS missing_pct,

    a.unique_cnt,
    ROUND(100.0 * a.unique_cnt / NULLIF(a.non_missing_cnt, 0), 2) AS unique_pct,

    COALESCE(mc.most_common_cnt, 0) AS most_common_cnt,
    ROUND(100.0 * COALESCE(mc.most_common_cnt, 0) / NULLIF(a.total_rows, 0), 2) AS most_common_pct,
    mc.most_common_value
  FROM agg a
  LEFT JOIN mc ON TRUE
)


/* =========================
   FINAL UNION (as requested)
========================= */
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
  SELECT 2 AS sort_order, * FROM score_customer_id
  UNION ALL
  SELECT 3 AS sort_order, * FROM score_loan_status
  UNION ALL
  SELECT 4 AS sort_oder, * FROM score_state
  UNION ALL
  SELECT 5 AS sort_order, * FROM score_term
  UNION ALL
  SELECT 6 AS sort_order, * FROM score_grade
) t
ORDER BY t.sort_order;

WITH
/* =========================
   helper pattern (ซ้ำ 4 ตัว)
   LOCK:
     amount/installment: mismatched < 0
     int_rate: mismatched < 0 OR > 100
========================= */

/* 1) loan_amount */
score_loan_amount AS (
  WITH base AS (
    SELECT loan_amount::numeric AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND v < 0) AS mismatched_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND v >= 0) AS valid_cnt
    FROM base
  ),
  stats AS (
    SELECT
      AVG(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS mean,
      STDDEV_SAMP(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS std,
      MIN(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS min,
      PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p25,
      PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p50,
      PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p75,
      MAX(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS max
    FROM base
  )
  SELECT
    'loan_amount'::text AS column_name,
    a.total_rows,
    a.valid_cnt,
    (100.0 * a.valid_cnt / NULLIF(a.total_rows, 0)) AS valid_pct,
    a.mismatched_cnt,
    (100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0)) AS mismatched_pct,
    a.missing_cnt,
    (100.0 * a.missing_cnt / NULLIF(a.total_rows, 0)) AS missing_pct,
    s.mean, s.std, s.min, s.p25, s.p50, s.p75, s.max
  FROM agg a
  CROSS JOIN stats s
),

/* 2) funded_amount */
score_funded_amount AS (
  WITH base AS (
    SELECT funded_amount::numeric AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND v < 0) AS mismatched_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND v >= 0) AS valid_cnt
    FROM base
  ),
  stats AS (
    SELECT
      AVG(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS mean,
      STDDEV_SAMP(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS std,
      MIN(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS min,
      PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p25,
      PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p50,
      PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p75,
      MAX(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS max
    FROM base
  )
  SELECT
    'funded_amount'::text AS column_name,
    a.total_rows,
    a.valid_cnt,
    (100.0 * a.valid_cnt / NULLIF(a.total_rows, 0)) AS valid_pct,
    a.mismatched_cnt,
    (100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0)) AS mismatched_pct,
    a.missing_cnt,
    (100.0 * a.missing_cnt / NULLIF(a.total_rows, 0)) AS missing_pct,
    s.mean, s.std, s.min, s.p25, s.p50, s.p75, s.max
  FROM agg a
  CROSS JOIN stats s
),

/* 3) int_rate */
score_int_rate AS (
  WITH base AS (
    SELECT int_rate::numeric AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND (v < 0 OR v > 100)) AS mismatched_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND v >= 0 AND v <= 100) AS valid_cnt
    FROM base
  ),
  stats AS (
    SELECT
      AVG(v) FILTER (WHERE v IS NOT NULL AND v >= 0 AND v <= 100) AS mean,
      STDDEV_SAMP(v) FILTER (WHERE v IS NOT NULL AND v >= 0 AND v <= 100) AS std,
      MIN(v) FILTER (WHERE v IS NOT NULL AND v >= 0 AND v <= 100) AS min,
      PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0 AND v <= 100) AS p25,
      PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0 AND v <= 100) AS p50,
      PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0 AND v <= 100) AS p75,
      MAX(v) FILTER (WHERE v IS NOT NULL AND v >= 0 AND v <= 100) AS max
    FROM base
  )
  SELECT
    'int_rate'::text AS column_name,
    a.total_rows,
    a.valid_cnt,
    (100.0 * a.valid_cnt / NULLIF(a.total_rows, 0)) AS valid_pct,
    a.mismatched_cnt,
    (100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0)) AS mismatched_pct,
    a.missing_cnt,
    (100.0 * a.missing_cnt / NULLIF(a.total_rows, 0)) AS missing_pct,
    s.mean, s.std, s.min, s.p25, s.p50, s.p75, s.max
  FROM agg a
  CROSS JOIN stats s
),

/* 4) installment */
score_installment AS (
  WITH base AS (
    SELECT installment::numeric AS v
    FROM raw.loans
  ),
  agg AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(*) FILTER (WHERE v IS NULL) AS missing_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND v < 0) AS mismatched_cnt,
      COUNT(*) FILTER (WHERE v IS NOT NULL AND v >= 0) AS valid_cnt
    FROM base
  ),
  stats AS (
    SELECT
      AVG(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS mean,
      STDDEV_SAMP(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS std,
      MIN(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS min,
      PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p25,
      PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p50,
      PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS p75,
      MAX(v) FILTER (WHERE v IS NOT NULL AND v >= 0) AS max
    FROM base
  )
  SELECT
    'installment'::text AS column_name,
    a.total_rows,
    a.valid_cnt,
    (100.0 * a.valid_cnt / NULLIF(a.total_rows, 0)) AS valid_pct,
    a.mismatched_cnt,
    (100.0 * a.mismatched_cnt / NULLIF(a.total_rows, 0)) AS mismatched_pct,
    a.missing_cnt,
    (100.0 * a.missing_cnt / NULLIF(a.total_rows, 0)) AS missing_pct,
    s.mean, s.std, s.min, s.p25, s.p50, s.p75, s.max
  FROM agg a
  CROSS JOIN stats s
)

/* =========================
   FINAL UNION + ROUND (ทีเดียว)
========================= */
SELECT
  t.column_name,
  t.total_rows,
  t.valid_cnt,
  ROUND(t.valid_pct::numeric, 2) AS valid_pct,
  t.mismatched_cnt,
  ROUND(t.mismatched_pct::numeric, 2) AS mismatched_pct,
  t.missing_cnt,
  ROUND(t.missing_pct::numeric, 2) AS missing_pct,

  ROUND(t.mean::numeric, 2) AS mean,
  ROUND(t.std::numeric, 2)  AS std,
  ROUND(t.min::numeric, 2)  AS min,
  ROUND(t.p25::numeric, 2)  AS p25,
  ROUND(t.p50::numeric, 2)  AS p50,
  ROUND(t.p75::numeric, 2)  AS p75,
  ROUND(t.max::numeric, 2)  AS max
FROM (
  SELECT 1 AS sort_order, * FROM score_loan_amount
  UNION ALL
  SELECT 2 AS sort_order, * FROM score_funded_amount
  UNION ALL
  SELECT 3 AS sort_order, * FROM score_int_rate
  UNION ALL
  SELECT 4 AS sort_order, * FROM score_installment
) t
ORDER BY t.sort_order;

