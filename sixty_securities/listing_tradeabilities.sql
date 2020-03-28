  -- find the most appropriate listing for each company, taking into account their primary-ness,
  -- whether we trade those countries, how long they've been around, and their liquidity
WITH
  universe AS (
    -- all universe checks are in this table and securities_all; we could consolidate these
  SELECT
    listing.fsym_id,
    -- can't put these in `raw` as it generates a BQ error (but not if you only have one - either one!)
    listing.exchange.country_iso IN (
    SELECT
      country_iso
    FROM
      `reference.traded_countries` ) AS is_tradeable_country,
    exchange.country_iso IN (
    SELECT
      country_iso
    FROM
      `reference.universe_countries` ) AS is_universe_country,
    -- this doesn't strictly need to be in this table, but we're using this table for this sort of universe data before
    -- it goes into `securities_all`
    type IN ('American Depositary Receipt',
      'Exchange Traded Fund (ETF-ETF)',
      'Share/Common/Ordinary',
      'Preferred Equity',
      'Global Depositary Receipt' ) AS is_universe_type,
    -- we don't trade any OTC stocks. Rare to find highly liquid stocks that are OTC. Expand this list as needed
    exchange.code NOT IN ('OTC') AS is_tradeable_exchange
  FROM
    `sixty_securities.companies`,
    UNNEST(securities),
    UNNEST(regionals) regional,
    UNNEST(listings) listing ),
  ts_metrics AS (
  SELECT
    fsym_id,
    (
    SELECT
      AS STRUCT MAX(date) latest_date,
      MIN(date) earliest_date,
      SQRT(COUNT(ts)) ts_count_sqrt,
      -- TODO: this should take the log of the proportion of the max, not the log and then the propotion of that
      -- It's currently conditional on the absolute size - e.g. if we did this in KRW we'd get a different result
      -- ...BUT we would prefer the average log liquidity, rather than the log average liquidity. I'm not sure
      -- those approaches can combine (unless we do something like what's the log proportion of the average liquidity
      -- through time)
      AVG(LOG(GREATEST(liquidity, 1))) liquidity_log_average,
      AVG(liquidity) liquidity_average
    FROM
      UNNEST(ts)).*
  FROM
    `sixty_security_ts.security_ts` security_ts),
  raw AS (
  SELECT
    factset_entity_id,
    company.name,
    ARRAY_AGG((
      SELECT
        AS STRUCT listing.fsym_id AS fsym_listing_id,
        listing.name,
        security.fsym_id AS fsym_security_id,
        regional.fsym_id AS fsym_regional_id,
        security.fsym_primary_equity_id,
        exchange.country_iso AS country_iso,
        security.fsym_id = security.fsym_primary_equity_id AS is_primary_security,
        regional.fsym_id = security.fsym_primary_regional_id AS is_primary_regional,
        listing.fsym_id = regional.fsym_primary_listing_id AS is_primary_listing,
        is_tradeable_country,
        is_tradeable_exchange,
        is_universe_country,
        is_universe_type,
        -- While we have preferred in our universe, it's generally not as good represetation
        -- of changes in company value than common
        security.type != 'Preferred Equity' AS is_common_stock,
        ts_metrics.* EXCEPT (fsym_id))) listing_tradeabilities
  FROM (`sixty_securities.companies` company
    CROSS JOIN
      UNNEST(securities) security
    CROSS JOIN
      UNNEST(regionals) regional
    CROSS JOIN
      UNNEST(listings) listing)
      -- not all companies are covered in ts_metrices, so we need to left join 
      -- (which forces us to do the cross joins)
  LEFT JOIN
    ts_metrics
  ON
    ts_metrics.fsym_id = regional.fsym_id
  JOIN
    universe
  ON
    universe.fsym_id = listing.fsym_id
  GROUP BY
    1,
    2 ),
  normalized AS (
  SELECT
    factset_entity_id,
    name,
    ARRAY((
      SELECT
        AS STRUCT *,
        -- is the latest security
        CAST(latest_date = MAX(latest_date) OVER () AS int64) * 2
        --
        +CAST(is_primary_security AS int64) * 1
        --.
        +CAST(is_primary_regional AS int64) * 2
        --.
        +CAST(is_primary_listing AS int64) * 4
        --.
        +CAST(is_common_stock AS int64) * 3
        --
        + safe_divide(liquidity_log_average,
          MAX(liquidity_log_average) OVER ()) * 5
        --
        + safe_divide(ts_count_sqrt,
          MAX(ts_count_sqrt) OVER ()) * 2
        --
        AS score,
        -- notes for debugging
        MAX(liquidity_log_average) OVER () AS max_liquidity_log_average,
        MAX(ts_count_sqrt) OVER () AS max_count_sqrt_ts,
        MAX(latest_date) OVER () AS max_date
      FROM
        UNNEST (listing_tradeabilities) ) ) listing_tradeabilities
  FROM
    raw),
  -- scores for sixty's purposes - so in the countries we trade
  normalized_sixty AS (
  SELECT
    factset_entity_id,
    name,
    ARRAY((
      SELECT
        AS STRUCT *,
        score
        --
        + CAST(is_tradeable_country AS int64) * 7
        --.
        +CAST(is_universe_country AS int64) * 4
        --
        +CAST(is_tradeable_exchange AS int64) * 4
        --
        AS score_sixty
      FROM
        UNNEST (listing_tradeabilities)
      ORDER BY
        score_sixty DESC) ) listing_tradeabilities
  FROM
    normalized)
SELECT
  factset_entity_id,
  name,
  -- each item of our equities table
  (
  SELECT
    AS STRUCT fsym_security_id,
    fsym_listing_id,
    fsym_regional_id,
    is_tradeable_country,
    is_universe_country,
    is_universe_type
  FROM
    UNNEST(listing_tradeabilities)
  ORDER BY
    score_sixty DESC
  LIMIT
    1) best_listing,
  -- for some metrics, we need a regional per security - e.g. market cap
  -- use the general version rather than the sixty version, as we don't need to trade it
  ARRAY(
  SELECT
    AS STRUCT fsym_security_id,
    ARRAY_AGG((
      SELECT
        fsym_regional_id )
    ORDER BY
      score DESC
    LIMIT
      1)[safe_ORDINAL(1)] fsym_regional_id
  FROM
    UNNEST(listing_tradeabilities)
  GROUP BY
    1) best_regional_by_security,
  listing_tradeabilities
FROM
  normalized_sixty