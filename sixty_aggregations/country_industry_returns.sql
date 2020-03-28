-- TODO: delete, as now in investment

WITH
  lagged AS (
  SELECT
    exchange.country AS exchange_country,
    company.industry AS industry,
    date,
    return_excess,
    -- lag so no LFB in market_cap
    LAG(market_cap_usd, 1) OVER (PARTITION BY exchange.country, company.industry ORDER BY date) AS market_cap_usd
  FROM
    `sixty_securities.securities`,
    UNNEST(ts)
  WHERE
    exchange.country IS NOT NULL
    AND company.industry IS NOT NULL
    AND ARRAY_LENGTH(ts) > 0
    -- exclude GDRs & ADRs, because they aren't representative of the country
    -- we do want to select by exchange though, because the returns should be aligned by closing time
    AND type = 'Share/Common/Ordinary'
    -- TODO: no longer needed, now we filter for universe anyway
    AND exchange.country_iso IN (
    SELECT
      country_iso
    FROM
      `sixty_listings.traded_countries`) ),
  industry_returns AS (
  SELECT
    exchange_country,
    industry,
    date,
    SUM(return_excess * market_cap_usd) / SUM(market_cap_usd) AS return_excess
  FROM
    lagged
  GROUP BY
    1,
    2,
    3)
SELECT
  exchange_country,
  industry,
  -- we could take out initial periods of null returns, to cut space
  ARRAY_AGG(STRUCT(date,
      return_excess)
  ORDER BY
    date ) AS ts
FROM
  industry_returns
GROUP BY
  exchange_country,
  industry