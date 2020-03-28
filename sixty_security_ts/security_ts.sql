WITH
  shares_outstandings_pit AS (
  SELECT
    fsym_id,
    ARRAY_AGG((
      SELECT
        AS STRUCT sho.* EXCEPT (fsym_id,
          p_date ),
        p_date AS date)) ts
  FROM
    `factset_prices_v2.fp_basic_shares_hist` sho
  GROUP BY
    fsym_id),
  shares_outstandings AS (
  SELECT
    fsym_id,
    ARRAY(
    SELECT
      AS STRUCT date,
      LAST_VALUE(P_COM_SHS_OUT IGNORE NULLS) OVER (ORDER BY date) * 1000 AS shares_outstanding,
      LAST_VALUE(P_COM_SHS_OUT IGNORE NULLS) OVER (ORDER BY date) * 1000 / cumulative_split_factor AS shares_outstanding_adjusted
    FROM
      UNNEST(security_dates.date) date
    LEFT JOIN
      UNNEST(cumulative_factors.ts)
    USING
      (date)
    LEFT JOIN
      UNNEST(shares_outstandings_pit.ts)
    USING
      (date)) ts
  FROM
    `sixty_security_ts.security_dates` security_dates
  LEFT JOIN
    shares_outstandings_pit
  USING
    (fsym_id)
  LEFT JOIN
    `sixty_security_ts.cumulative_factors` cumulative_factors
  USING
    (fsym_id) )
SELECT
  fsym_id,
  ARRAY(
  SELECT
    AS STRUCT returns_ts.*,
    shares_outstanding,
    shares_outstanding_adjusted,
    -- Fill over the current market prices (price_close is current only) where
    -- `is_current_price` is False, but NOT where `is_valid_price` is False
    -- otherwise a dead security will have market cap filled forward without
    -- limit.
    -- NB we generate market caps and fill rather than use filled prices, to
    -- ensure market_cap doesn't update when shares_outstanding change but the price
    -- isn't valid.
    IF(is_valid_price,
      LAST_VALUE(price_close * shares_outstanding IGNORE NULLS) OVER (ORDER BY date),
      NULL) AS market_cap,
    IF(is_valid_price,
      LAST_VALUE(price_close_usd * shares_outstanding IGNORE NULLS) OVER (ORDER BY date),
      NULL) AS market_cap_usd,
    shares_outstanding_adjusted - LAG(shares_outstanding_adjusted, 1, 0) OVER (ORDER BY returns_ts.date) AS flow,
    LOG(nullif(shares_outstanding_adjusted,
        0) / LAG(shares_outstanding_adjusted, 1) OVER (ORDER BY returns_ts.date)) AS flow_share,
    AVG(volume_usd) OVER recent_quarter AS liquidity,
    -- this is useful if you need to find the number of business days between two rows
    COUNT(*) OVER (ORDER BY date) AS expanding_bday_count
  FROM
    UNNEST(return.ts) returns_ts
  JOIN
    UNNEST(shares_outstandings.ts)
  USING
    (date)
  WINDOW
    recent_quarter AS (
    ORDER BY
      date ROWS BETWEEN 60 PRECEDING
      AND 1 PRECEDING ) ) ts
FROM
  `sixty_security_ts.returns` return
LEFT JOIN
  shares_outstandings
USING
  (fsym_id)