WITH
  sparse_interest_rates AS (
  SELECT
    currency AS currency,
    ARRAY_AGG((
      SELECT
        AS STRUCT sge.date,
        sge.value /100 AS interest_rate )
    ORDER BY
      date) ts
  FROM
    `sixty_macro.currency_interest_rate_map`
  JOIN
    `quandl.sge_data` AS sge
  USING
    (code)
  GROUP BY
    currency ),
  dates_dense AS (
  SELECT
    currency,
    ARRAY_AGG( date) date
  FROM
    sparse_interest_rates,
    -- TODO: replace with more robust & dynamic table
    `reference.bdays`
  GROUP BY
    currency )
SELECT
  currency,
  ARRAY(
  SELECT
    AS STRUCT
    -- anything we want to fill down we use `latest`, otherwise we use `ts`
    -- as `ts` is matched only if already exists, whereas latest is joined based on latest value
    date,
    LAST_VALUE(interest_rate IGNORE NULLS) OVER (ORDER BY date) interest_rate
  FROM
    UNNEST(dates_dense.date) date
  LEFT JOIN
    UNNEST(sparse.ts) ts
  USING
    (date)) ts
FROM
  dates_dense
JOIN
  sparse_interest_rates AS sparse
USING
  (currency)
