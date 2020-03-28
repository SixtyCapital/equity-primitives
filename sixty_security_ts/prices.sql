  -- is_current: is a correct price for the relevant date. Defines whether it should have a return. Should be tradeable on that date
  -- is_valid: is recently a correct price; differing from `is_current` in times such as holidays
WITH
  prices AS (
  SELECT
    fsym_id,
    currency,
    ARRAY_AGG((
      SELECT
        AS STRUCT p_date AS date,
        p_price AS price,
        p_price_open AS price_open,
        p_price_high AS price_high,
        p_price_low AS price_low,
        p_volume AS volume )) ts
  FROM
    `factset_prices_v2.fp_basic_prices` prices
  GROUP BY
    fsym_id,
    currency ),
  most_used_currencies AS (
    -- there's a small risk that there are multiple currencies per security, which would cause multiple rows per security and an exploding join downstream
    -- this ensures only the most frequently quoted currency for each security is included. It's not a great solution, since
    -- we're throwing away data very early upstream (and creating LFB). But this isn't expected to occur frequently.
    -- I tried to structure this a WHERE clause, but not successfully
  SELECT
    fsym_id,
    ARRAY_AGG( currency
    ORDER BY
      ARRAY_LENGTH(ts) DESC
    LIMIT
      1 ) [safe_ORDINAL(1)] AS currency
  FROM
    prices
  GROUP BY
    fsym_id ),
  prices_contiguous AS (
    -- ensure the values are over contigous dates
    -- also fills the exch_rate_usd, in case it's not published (this happened Christmas 2018)
  SELECT
    fsym_id,
    currency,
    ARRAY(
    SELECT
      AS STRUCT * EXCEPT ( volume,
        exch_rate_usd),
      -- We restrict these to 60 days so they don't fill multiple years forward
      LAST_VALUE( price IGNORE NULLS) OVER recent AS price_continuous,
      LAST_VALUE( exch_rate_usd IGNORE NULLS) OVER recent AS exch_rate_usd,
      ifnull(volume,
        0) AS volume
    FROM
      UNNEST(date) date
    LEFT JOIN
      UNNEST(prices.ts)
    USING
      (date)
    LEFT JOIN
      UNNEST(exchange_rates.ts)
    USING
      (date)
    WINDOW
      recent AS (
      ORDER BY
        date ROWS BETWEEN 60 PRECEDING
        AND CURRENT ROW ) ) ts
  FROM
    `sixty_security_ts.security_dates`
  JOIN
    prices
  USING
    (fsym_id)
  JOIN
    most_used_currencies
  USING
    (fsym_id,
      currency )
  LEFT JOIN
    `sixty_macro.exchange_rates` exchange_rates
  USING
    (currency) ),
  prices_adjusted AS (
  SELECT
    fsym_id,
    currency,
    ARRAY(
    SELECT
      AS STRUCT prices_ts.* EXCEPT (volume),
      price * cumulative_split_factor * cumulative_spinoff_dividend_factor AS price_adjusted,
      price_open * cumulative_split_factor * cumulative_spinoff_dividend_factor AS price_open_adjusted,
      price * exch_rate_usd AS price_usd,
      price_open * exch_rate_usd AS price_open_usd,
      price * cumulative_split_factor * cumulative_spinoff_dividend_factor * exch_rate_usd AS price_adjusted_usd,
      price_open * cumulative_split_factor * cumulative_spinoff_dividend_factor * exch_rate_usd AS price_open_adjusted_usd,
      volume * 1000 AS volume,
      volume * 1000 * exch_rate_usd * price AS volume_usd,
      -- divided rather than multiplied, since if price_adjusted is higher, volume_adjusted must be lower
      volume * 1000 / cumulative_split_factor AS volume_adjusted,
      cash_dividend_return
    FROM
      UNNEST(prices.ts) prices_ts
    LEFT JOIN
      UNNEST(cumulative_factors.ts) cf_ts
    USING
      (date) ) ts
  FROM
    prices_contiguous AS prices
  LEFT JOIN
    `sixty_security_ts.cumulative_factors` cumulative_factors
  USING
    (fsym_id) ),
  is_current_prices AS (
  SELECT
    fsym_id,
    ARRAY(
    SELECT
      AS STRUCT *,
      -- requires to either be tradeable up to yesterday, or be liquid on its first day today.
      (
        -- We include "be liquid today" to not exclude every company on its first day.
        -- While it's some LFB, it's also a safe assumption that we could have some forecast as to whether it would be liquid on its first day
        LEAST(volume_usd > 100000, COUNT(*) OVER recent = 0 ) OR
        -- To be tradeable requires:
        LEAST(
          -- Some volume, and price being high enough that ticks aren't large returns, and have some recent volume. Could also add market cap constraints etc
          volume > 0, price_usd > 0.1, AVG(price_usd) OVER recent > 0.25,
          -- Recent volume is to filter out securities that are basically untradable, and then suddenly come online for one day
          -- potentially this should be median, but no function to do taht over a rolling window (PERCENTILE_CONT doesn't operate over windows)
          AVG(volume_usd) OVER recent > 10000,
          -- of recent values, at least half have greater than zero volume data (this is also robust to fewer than twenty rows)
          AVG(CAST(volume > 0 AS int64)) OVER recent > 0.5) )
      --
      IS TRUE AS is_current_price,
      date IN UNNEST(holidays.date) AS is_holiday
    FROM
      UNNEST(prices.ts)
    WINDOW
      recent AS (
      ORDER BY
        date ROWS BETWEEN 20 PRECEDING
        -- don't include current row so no LFB
        AND 1 PRECEDING ) ) ts
  FROM
    prices_adjusted AS prices
  JOIN
    `factset_sym.sym_coverage`
  USING
    (fsym_id)
  LEFT JOIN
    `sixty_security_ts.holidays` holidays
  ON
    exchange=fref_listing_exchange ),
  is_valid_prices AS (
  SELECT
    fsym_id,
    ARRAY(
    SELECT
      AS STRUCT *,
      -- is_valid is defined as:
      GREATEST(
        -- either a. is_current...
        is_current_price,
        -- or b. is_holiday and was current within the past few days
        COUNTIF(is_current_price) OVER recent > 0
        AND is_holiday,
        -- or c. was current within the past few days, and has been well above the cutoff recently, but has zero volume today, suggesting a Factset mistake
        LEAST(COUNTIF(is_current_price) OVER recent > 0, AVG(volume_usd) OVER recent > 100000, volume=0)
        --  protect against nulls, since gaps in factset series cause nulls in those columns
        ) IS TRUE AS is_valid_price
    FROM
      UNNEST(is_current_prices.ts)
    WINDOW
      recent AS (
      ORDER BY
        -- This needs to be > 7 to be robust to the death of Japanese Emperors
        date ROWS BETWEEN 9 PRECEDING
        AND CURRENT ROW ) ) ts
  FROM
    is_current_prices ),
  current_prices AS (
  SELECT
    fsym_id,
    ARRAY(
    SELECT
      AS STRUCT *
    FROM
      UNNEST(ts)
    WHERE
      is_current_price) ts
  FROM
    is_current_prices )
SELECT
  fsym_id,
  currency,
  ARRAY(
  SELECT
    AS STRUCT
    -- Here we use:
    -- original: dates from the original table, no filling, no impact from valid
    -- current_: is a correct price for the relevant date
    -- LAST_VALUE(current_...): the most recent valid price, filled over any non-valid prices
    date,
    -- We restrict these to 60 days so they don't fill multiple years forward
    LAST_VALUE(current_.price IGNORE NULLS) OVER recent AS price,
    LAST_VALUE(current_.price_usd IGNORE NULLS) OVER recent AS price_usd,
    LAST_VALUE(current_.price_adjusted IGNORE NULLS) OVER recent AS price_adjusted,
    LAST_VALUE(current_.price_adjusted_usd IGNORE NULLS) OVER recent AS price_adjusted_usd,
    original.volume,
    original.volume_usd,
    original.volume_adjusted,
    original.cash_dividend_return,
    current_.price_open,
    current_.price_open_usd,
    current_.price_open_adjusted,
    current_.price_open_adjusted_usd,
    current_.price AS price_close,
    current_.price_usd AS price_close_usd,
    current_.price_adjusted AS price_close_adjusted,
    current_.price_adjusted_usd AS price_close_adjusted_usd,
    current_.price_high,
    current_.price_low,
    is_valid.is_current_price,
    is_valid_price,
    is_valid.is_holiday,
    -- even when not otherwise valid; useful at the beginning of periods before prices become valid
    original.price_continuous
  FROM
    UNNEST(original.ts) original
  JOIN
    UNNEST(is_valid_prices.ts) is_valid
  USING
    (date)
  LEFT JOIN
    UNNEST(current_.ts) current_
  USING
    (date)
  WINDOW
    recent AS (
    ORDER BY
      date ROWS BETWEEN 60 PRECEDING
      AND CURRENT ROW ) ) ts
FROM
  prices_adjusted AS original
JOIN
  is_valid_prices
USING
  (fsym_id)
LEFT JOIN
  current_prices AS current_
USING
  (fsym_id)