  -- a mapping of company -> securities -> regionals -> listings
  -- this is an external API, unlike most tables that don't share
  -- a name with their dataset
WITH
  isin AS(
  SELECT
    *
  FROM
    `factset_sym.sym_isin`
  UNION ALL
  SELECT
    *
  FROM
    `factset_sym.sym_xc_isin`
    -- occasionally fsym_id will be linked to isins in both tables - this ensures there's only one
    -- and add a uniqueness filter to isins too for safety
  WHERE
    fsym_id NOT IN (
    SELECT
      fsym_id
    FROM
      `factset_sym.sym_isin` )
    AND isin NOT IN (
    SELECT
      isin
    FROM
      `factset_sym.sym_isin` ) ),
  -- could move this to a separate table
  geo_codes AS (
  SELECT
    *
  FROM
  -- This looks a bit awkward but the alternative is to have 8 select statements each with column names combined with UNIONs.
  -- Or are there alternatives?
    UNNEST(ARRAY<STRUCT<region_code string, geo_code string>> [
      --
      ('E',
        'EMEA'),
      --
      ('M',
        'EMEA'),
      --
      ('F',
        'EMEA'),
      --
      ('A',
        'AP'),
      --
      ('Y',
        'AP'),
      --
      ('L',
        'AM'),
      --
      ('N',
        'AM') ]) ),
  exchange AS (
  SELECT
    FREF_EXCHANGE_CODE AS code,
    FREF_EXCHANGE_DESC AS name,
    COUNTRY_DESC AS country,
    ISO_COUNTRY AS country_iso,
    REGION_DESC AS region,
    REGION_CODE AS region_code,
    geo_code
  FROM
    `factset_ref.fref_sec_exchange_map`
  JOIN
    `factset_ref.country_map`
  ON
    FREF_EXCHANGE_LOCATION_CODE = ISO_COUNTRY
  LEFT JOIN
    `factset_ref.region_map`
  USING
    (region_code)
  LEFT JOIN
    geo_codes
  USING
    (region_code) ),
  latest_entities AS (
    -- the latest entity for each security - no need to ever have an older entity
  SELECT
    fsym_id,
    ARRAY_AGG((
      SELECT
        factset_entity_id )
    ORDER BY
      end_date IS NULL DESC, end_date DESC)[safe_ORDINAL(1)] AS factset_entity_id
  FROM
    -- we need to use the prices dataset, as Factset do not have this data within the factset_sym data
    `factset_prices_v2.fp_sec_entity_hist`
  GROUP BY
    1),
  entity_security_mappings AS (
  SELECT
    -- aggregate companies by their primary security (`fsym_primary_equity_id`) 's mapping to entity
    factset_entity_id,
    cov.fsym_id AS fsym_id
  FROM
    latest_entities
  JOIN
    `factset_sym.sym_coverage` cov
  ON
    -- Note - we have to map through primary_equity_id, because the entity mapping table does not have entries for all securities
    fsym_primary_equity_id = latest_entities.fsym_id
  WHERE
    security_flag ),
  -- array of the listings for each regional.
  -- doing with each table being an array makes the group by & joining much easier
  -- even though it seems a bit misnamed
  listings AS (
  SELECT
    fsym_regional_id,
    ARRAY_AGG(STRUCT(cov.fsym_id,
        proper_name AS name,
        fref_listing_exchange AS exchange_code,
        exchange,
        active_flag,
        index.fsym_id AS country_index_fsym_id)
    ORDER BY
      cov.fsym_id ) listings
  FROM
    `factset_sym.sym_coverage` cov
  LEFT JOIN
    exchange
  ON
    exchange.code = FREF_LISTING_EXCHANGE
  LEFT JOIN
    `sixty_macro.country_index` index
  USING
    (country_iso)
  WHERE
    listing_flag = TRUE
    AND fsym_regional_id != ''
  GROUP BY
    1 ),
  regionals AS (
  SELECT
    fsym_security_id,
    ARRAY_AGG((
      SELECT
        AS STRUCT fsym_id,
        sedol,
        ticker_region,
        SUBSTR(ticker_region, 0, LENGTH(ticker_region) - 3) AS ticker,
        -- this is the region part of the ticker
        SUBSTR(ticker_region, LENGTH(ticker_region) - 1, LENGTH(ticker_region)) AS region_from_ticker,
        proper_name AS name,
        bbid,
        bcid,
        gsid,
        fsym_primary_listing_id,
        currency,
        active_flag,
        listings.* EXCEPT (fsym_regional_id ))
    ORDER BY
      fsym_id ) regionals
  FROM
    `factset_sym.sym_coverage`
  LEFT JOIN
    listings
  ON
    fsym_id = listings.fsym_regional_id
  LEFT JOIN
    `factset_sym.sym_sedol`
  USING
    (fsym_id)
  LEFT JOIN
    `factset_sym.sym_ticker_region`
  USING
    (fsym_id )
  LEFT JOIN
    `marquee.regionals`
  USING
    (sedol)
  WHERE
    regional_flag = TRUE
  GROUP BY
    1 ),
  securities AS (
  SELECT
    factset_entity_id,
    ARRAY_AGG((
      SELECT
        AS STRUCT fsym_id,
        fsym_primary_equity_id,
        cusip,
        isin.isin,
        proper_name AS name,
        universe_type AS asset_class,
        FREF_SECURITY_TYPE AS type_code,
        FREF_SECURITY_TYPE_DESC AS type,
        fsym_primary_listing_id AS fsym_primary_regional_id,
        active_flag,
        regionals.* EXCEPT (fsym_security_id ))
    ORDER BY
      fsym_id ) securities
  FROM
    entity_security_mappings
  LEFT JOIN
    `factset_sym.sym_coverage` cov
  USING
    (fsym_id)
  LEFT JOIN
    `factset_sym.sym_cusip`
  USING
    (fsym_id)
  LEFT JOIN
    isin
  USING
    (fsym_id)
  LEFT JOIN
    `factset_ref.fref_security_type_map`
  ON
    (FREF_SECURITY_TYPE_code = FREF_SECURITY_TYPE )
  LEFT JOIN
    regionals
  ON
    fsym_id = regionals.fsym_security_id
  WHERE
    security_flag = TRUE
  GROUP BY
    1)
SELECT
  factset_entity_id,
  ENTITY_PROPER_NAME AS name,
  COUNTRY_DESC AS country,
  ISO_COUNTRY AS country_iso,
  REGION_DESC AS region,
  REGION_CODE AS region_code,
  FACTSET_INDUSTRY_DESC AS industry,
  FACTSET_INDUSTRY_CODE AS industry_code,
  geo_code,
  PRIMARY_SIC_CODE AS sic,
  FACTSET_SECTOR_DESC AS sector,
  SECTOR_CODE AS sector_code,
  securities.* EXCEPT (factset_entity_id )
FROM
  securities
JOIN
  `factset_sym.sym_entity`
USING
  (factset_entity_id)
LEFT JOIN
  `factset_sym.sym_entity_sector` entity_sector
USING
  (factset_entity_id )
LEFT JOIN
  `factset_ref.factset_sector_map`
ON
  SECTOR_CODE = FACTSET_SECTOR_CODE
LEFT JOIN
  `factset_ref.factset_industry_map`
ON
  INDUSTRY_CODE = FACTSET_INDUSTRY_CODE
LEFT JOIN
  `factset_ref.sic_map`
ON
  PRIMARY_SIC_CODE = SIC_CODE
LEFT JOIN
  `factset_ref.country_map`
USING
  (ISO_COUNTRY)
LEFT JOIN
  `factset_ref.region_map`
USING
  (region_code)
LEFT JOIN
  geo_codes
USING
  (region_code)