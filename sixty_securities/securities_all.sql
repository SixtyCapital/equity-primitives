  -- all vendor data about all securities. One row per security, using the most tradeable regional
WITH
  security_info AS (
    -- key data non-ts data pulled into the main table
  SELECT
    regional.fsym_id,
    company.name,
    company.factset_entity_id,
    security.fsym_id AS fsym_security_id,
    regional.fsym_id AS fsym_regional_id,
    listing.fsym_id AS fsym_listing_id,
    security.cusip,
    security.isin,
    regional.sedol,
    regional.currency,
    (
    SELECT
      AS STRUCT company.* EXCEPT (securities)) company,
    security.asset_class,
    security.type,
    regional.ticker,
    regional.ticker_region,
    regional.bcid,
    regional.bbid,
    regional.gsid,
    listing.exchange,
    listing.exchange_code,
    listing.country_index_fsym_id,
    -- recreate the securities map with the best regional id at the correct level
    ARRAY(
    SELECT
      AS STRUCT securities.*,
      fsym_regional_id AS best_fsym_regional_id
    FROM
      UNNEST(securities) securities
    JOIN
      UNNEST(best_regional_by_security)
    ON
      fsym_id = fsym_security_id ) securities
  FROM
    `sixty_securities.companies` company,
    UNNEST(securities) security,
    UNNEST(regionals) regional,
    UNNEST(listings) listing
  JOIN
    `sixty_securities.listing_tradeabilities` listing_tradeabilities
  ON
    -- filter down so only one listing per company. Could also do this with a WHERE
    listing.fsym_id = listing_tradeabilities.best_listing.fsym_listing_id ),
  company_ts_flat AS (
    -- ts data that we need to aggregate by company
  SELECT
    factset_entity_id,
    date,
    SUM(market_cap) market_cap,
    SUM(market_cap_usd) market_cap_usd
    -- Not currently using this, as unsure how co aggregate securities (and not _that_ helpful)
    -- SUM(volume_usd) volume_usd
    -- should we add flow_usd?
  FROM
    -- I don't think we can do these joins without unnesting literally everything
    -- because there's no way to join the rows at the nested level - one has
    -- fsym_id and the other factset_entity_id
    security_info,
    UNNEST(securities) security
  JOIN (`sixty_security_ts.security_ts` security_ts
    CROSS JOIN
      UNNEST(ts))
  ON
    security.best_fsym_regional_id = security_ts.fsym_id
  WHERE
    security.type = 'Share/Common/Ordinary'
  GROUP BY
    1,
    2),
  company_ts AS (
  SELECT
    factset_entity_id,
    ARRAY_AGG((
      SELECT
        AS STRUCT company_ts_flat.* EXCEPT (factset_entity_id))) ts
  FROM
    company_ts_flat
  GROUP BY
    1),
  universe_inputs AS (
  SELECT
    factset_entity_id,
    ARRAY((
      SELECT
        AS STRUCT security_ts.date,
        company_ts.* EXCEPT (date),
        ifnull(MAX(company_ts.market_cap_usd) OVER recent,
          0) recent_max_market_cap_usd,
        ifnull(MAX(volume_usd) OVER recent,
          0) recent_max_volume_usd,
        -- used in universe below - do we have market cap, with an allowance for ETFs
        -- we need to recheck this because the selected regionals may have different availability from the regional we use
        GREATEST(company_ts.market_cap IS NOT NULL, type = 'Exchange Traded Fund (ETF-ETF)' ) AS is_market_cap_valid
      FROM
        UNNEST(security_ts.ts) security_ts
      LEFT JOIN
        UNNEST(company_ts.ts) company_ts
      USING
        (date)
      WINDOW
        recent AS (
        ORDER BY
          date ROWS BETWEEN 20 PRECEDING
          -- don't include current row so no LFB
          AND 1 PRECEDING ) ) ) ts
  FROM
    security_info
  LEFT JOIN
    company_ts
  USING
    (factset_entity_id)
  LEFT JOIN
    `sixty_security_ts.security_ts` security_ts
  USING
    (fsym_id) )
SELECT
  security_info.* EXCEPT
  -- moved to end
  (securities),
  ARRAY(
  SELECT
    AS STRUCT securities_ts.* EXCEPT (market_cap,
      market_cap_usd),
    company_ts.market_cap,
    company_ts.market_cap_usd,
    securities_ts.market_cap AS market_cap_regional,
    securities_ts.market_cap AS market_cap_usd_regional,
    -- All universe checks are in this table and listing_tradeabilities; we could consolidate these.
    -- Currently mainly using market_cap, with a fallback for volume for ETFs given they don't have shares outstanding.
    -- We could extend to using a broader score based on liquidity etc
    -- We use max to prevent flickering
    LEAST(is_valid_price, is_market_cap_valid, GREATEST(recent_max_market_cap_usd > 100e6, recent_max_volume_usd > 10e6 ) ) AS is_universe_liquidity,
    LEAST(is_valid_price, is_market_cap_valid, GREATEST(recent_max_market_cap_usd > 100e6, recent_max_volume_usd > 10e6), best_listing.is_universe_country, best_listing.is_universe_type ) AS is_universe,
    LEAST(is_valid_price, is_market_cap_valid, GREATEST(recent_max_market_cap_usd > 100e6, recent_max_volume_usd > 10e6) ) AS is_tradeable_liquidity,
    LEAST(is_current_price, GREATEST(recent_max_market_cap_usd > 100e6, recent_max_volume_usd > 10e6), best_listing.is_tradeable_country, best_listing.is_universe_type ) AS is_tradeable,
    earnings_ts.is_earnings_date,
    earnings_ts.days_to_next_earnings
  FROM
    UNNEST(securities_ts.ts) securities_ts
  LEFT JOIN
    UNNEST(universe_inputs.ts) AS company_ts
  USING
    (date)
  LEFT JOIN
    UNNEST(earnings_dates.ts) earnings_ts
  USING
    (date) ) ts,
  (
  SELECT
    AS STRUCT *
  FROM
    UNNEST(securities_ts.ts)
  ORDER BY
    date DESC
  LIMIT
    1) AS latest,
  ((
    SELECT
      MIN(date)
    FROM
      UNNEST(securities_ts.ts))) AS min_date,
  securities,
  (
  SELECT
    AS STRUCT revere_industry.* EXCEPT (factset_entity_id )) revere_industry
FROM
  security_info
JOIN
  `sixty_securities.listing_tradeabilities` listing_tradeabilities
USING
  (factset_entity_id)
LEFT JOIN
  `sixty_security_ts.security_ts` securities_ts
USING
  (fsym_id)
JOIN
  universe_inputs
USING
  (factset_entity_id)
  -- left join because only common shares are in company_ts, not ETFs
LEFT JOIN
  `revere_industry.company_industry` revere_industry
USING
  (factset_entity_id)
LEFT JOIN
  `sixty_security_ts.earnings_dates` earnings_dates
USING
  (fsym_id)