WITH
  dates AS (
  SELECT
    DISTINCT date
  FROM
    `factset_ref.fx_rates_usd`
  ORDER BY
    date)
SELECT
  iso_currency AS currency,
  ARRAY_AGG((
    SELECT
      AS STRUCT date,
      exch_rate_usd )
  ORDER BY
    date) ts
FROM
  `factset_ref.fx_rates_usd`
GROUP BY
  currency
UNION ALL
SELECT
  'USD' AS currency,
  ARRAY(
  SELECT
    AS STRUCT date,
    1.0 AS exch_rate_usd
  FROM
    dates) ts
