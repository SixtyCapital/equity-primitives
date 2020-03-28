WITH
  prices AS (
  SELECT
    p_date AS date,
    p_volume AS volume,
    -- organize by exchange. We could change this to listing country.
    -- We can't use currency even though it's on this table, as there are EUR differences
    fref_listing_exchange AS exchange
  FROM
    `factset_prices_v2.fp_basic_prices`
  JOIN
    `factset_sym.sym_coverage`
  USING
    (fsym_id) ),
  dates AS (
  SELECT
    date
  FROM
    UNNEST((
      SELECT
        GENERATE_DATE_ARRAY(MIN(p_date), MAX(p_date))
      FROM
        `factset_prices_v2.fp_basic_prices`)) date
  WHERE
    EXTRACT(dayofweek
    FROM
      date) BETWEEN 2
    AND 6 ),
  exchanges AS (
  SELECT
    DISTINCT fref_listing_exchange AS exchange
  FROM
    `factset_sym.sym_coverage` ),
  counts AS (
  SELECT
    date,
    exchange,
    COUNTIF(volume > 0) positive_volume_count,
    COUNTIF(volume IS NOT NULL) non_null_count
  FROM
    dates
  CROSS JOIN
    exchanges
  LEFT JOIN
    prices
  USING
    (date,
      exchange)
  GROUP BY
    exchange,
    date ),
  recent_counts AS (
  SELECT
    date,
    exchange,
    positive_volume_count,
    -- how many securities for that exchange have non-zero volume
    AVG(positive_volume_count) OVER recent_in_exchange AS recent_count,
    -- how many securities for that exchange have non-zero volume, as a proportion of recent days
    safe_divide(positive_volume_count,
      AVG(positive_volume_count) OVER recent_in_exchange) AS proportion_count,
    -- exchange need at least 3 days with data out of the past 10 (or data today), otherwise we consider them not to have data, rather than be on holiday
    GREATEST(non_null_count > 0, COUNTIF(positive_volume_count > 0) OVER recent_in_exchange > 3) AS is_valid
  FROM
    counts
  WINDOW
    recent_in_exchange AS (
    PARTITION BY
      exchange
    ORDER BY
      date ROWS BETWEEN 10 PRECEDING
      AND 1 PRECEDING ) )
SELECT
  exchange,
  ARRAY_AGG( date) date
FROM
  recent_counts
WHERE
  is_valid AND
  -- less than 40% of securities with volume is a holiday
  -- we previously had 30%, but this caused an issue with returns on 2019-05-06, where the UK had a holiday
  -- because volumes are attached to a _regional_ rather than a listing, and the UK has lots of regionals 
  -- with listings elsewhere, the UK showed 31% of companies had a holiday.
  -- These sorts of problems are not unexpected given the derived nature of this table...
  proportion_count < 0.4
GROUP BY
  exchange