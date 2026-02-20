WITH norm AS (
  SELECT
    purpose,
    NULLIF(BTRIM(purpose), '') AS purpose_trim,
    LOWER(NULLIF(BTRIM(purpose), '')) AS purpose_norm
  FROM raw.loan_purposes
),
agg AS (
  SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE purpose_trim IS NULL) AS missing_cnt,
    COUNT(*) FILTER (WHERE purpose_trim IS NOT NULL) AS valid_cnt,
    COUNT(DISTINCT purpose_norm) FILTER (WHERE purpose_norm IS NOT NULL) AS unique_cnt,
    COUNT(*) FILTER (WHERE purpose_norm IS NOT NULL) AS non_missing_cnt
  FROM norm
)
SELECT
  'purpose' AS column_name,
  total_rows,
  valid_cnt,
  ROUND(100.0 * valid_cnt / NULLIF(total_rows, 0), 2) AS valid_pct,
  0 AS mismatched_cnt,
  0.00 AS mismatched_pct,
  missing_cnt,
  ROUND(100.0 * missing_cnt / NULLIF(total_rows, 0), 2) AS missing_pct,
  unique_cnt,
  ROUND(100.0 * unique_cnt / NULLIF(non_missing_cnt, 0), 2) AS unique_pct
FROM agg;

WITH norm AS (
  SELECT
    purpose,
    LOWER(NULLIF(BTRIM(purpose), '')) AS purpose_norm
  FROM raw.loan_purposes
)
SELECT
  purpose_norm,
  COUNT(*) AS cnt,
  STRING_AGG(purpose, ' | ' ORDER BY purpose) AS examples
FROM norm
WHERE purpose_norm IS NOT NULL
GROUP BY purpose_norm
HAVING COUNT(*) > 1
ORDER BY cnt DESC, purpose_norm;


SELECT purpose
FROM raw.loan_purposes
WHERE purpose IS NOT NULL
ORDER BY purpose;
