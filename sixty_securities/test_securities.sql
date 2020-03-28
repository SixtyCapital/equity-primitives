SELECT
  *
FROM
  UNNEST(ARRAY<STRUCT<test string, result bool>> [
    --
    ( 'verizon has approx number of ts dates',
      (
      SELECT
        ARRAY_LENGTH(ts) ct
      FROM
        `sixty_securities.securities`
      WHERE
        name LIKE 'Verizon Communications%') BETWEEN 5000
      AND 15000 ),
    --
    ( 'securities has approx correct number of securities with dates',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.securities`
      WHERE
        ARRAY_LENGTH(ts) > 0 ) BETWEEN 1e4
      AND 6e4
      -- 50k does seem like a lot
      ),
    --
    ('No duplicate fsym_id',
      (
      SELECT
        COUNT(*) AS ct
      FROM
        `sixty_securities.securities`
      GROUP BY
        fsym_id
      ORDER BY
        ct DESC
      LIMIT
        1 ) = 1 ),
    --
    ( 'no duplicate isin',
      (
      SELECT
        COUNT(*) AS ct
      FROM
        `sixty_securities.securities`
      WHERE
        isin IS NOT NULL
      GROUP BY
        isin
      ORDER BY
        ct DESC
      LIMIT
        1) = 1 ),
    --
    ( 'no duplicate listings in listing_tradeabilities',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.listing_tradeabilities`,
        UNNEST( listing_tradeabilities)
      GROUP BY
        fsym_listing_id
      ORDER BY
        1 DESC
      LIMIT
        1) =1),
    --
    ('Ronson (random UK small cap) does not have ts data',
      (
      SELECT
        COUNT(ts)
      FROM
        `sixty_securities.securities`,
        UNNEST(ts) ts
      WHERE
        fsym_id = 'V9H7Q5-R') = 0 ),
    --
    ('Ronson (random UK small cap) appears as a security',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.securities_all`
      WHERE
        fsym_id = 'V9H7Q5-R') = 1 ),
    --
    ('Verizon does not have null prices in normal times',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.securities`,
        UNNEST(ts) ts
      WHERE
        fsym_listing_id = 'JZTDC0-L'
        AND price_adjusted IS NULL
        AND date BETWEEN '2001-01-01'
        AND '2010-01-01') = 0),
    --
    ('Biggest market caps are accurate',
      -- check that the top 21 companies by market cap are in these 21
      -- only from 2005 - factset data is unreliable prior (reported to factset)
      (
        -- very convoluted query, but I went through a few iterations and this is the best I could do
      WITH
        max_market_caps AS (
        SELECT
          name,
          fsym_id,
          fsym_id IN( "PPC8D5-R",
            "MH33D6-R",
            "HTM0LK-R",
            "P8R3C2-R",
            "MCNYYL-R",
            "QG1HR7-R",
            "KPK586-R",
            "DBNXVB-R",
            "QLGSL2-R",
            "CTYNJ1-R",
            "HG6D4P-R",
            "KV0J41-R",
            "NNKD2Y-R",
            "VDY6QK-R",
            "JBJ78F-R",
            "GFJC62-R",
            -- cisco
            "FZXT6G-R",
            "HZ6Z7Q-R",
            -- intel
            "F5ZF5N-R",
            -- NTT DoCoMo
            "J4RDQ3-R",
            -- Vodafone
            'P6LTYW-R',
            -- Ericsson
            'VK7M4R-R',
            -- Pfizer
            'CSMTMQ-R',
            -- Walmart
            "VJ2X17-R",
            "LF992Y-R",
            "BL63XF-R",
            "DTKZ1Y-R",
            "VWF970-R" ) AS is_correct_top,
          (
          SELECT
            MAX(market_cap_usd)
          FROM
            UNNEST(ts)
          WHERE
            date BETWEEN '2000-01-01'
            AND '2018-01-01') max_mkt_cap
        FROM
          `sixty_securities.securities` ),
        top AS (
        SELECT
          fsym_id
        FROM
          max_market_caps
        ORDER BY
          max_mkt_cap DESC
        LIMIT
          28)
      SELECT
        --         *
        COUNT(*) = 28
      FROM
        max_market_caps
      WHERE
        (fsym_id IN (
          SELECT
            fsym_id
          FROM
            top)
          OR is_correct_top )
        --       ORDER BY
        --         max_mkt_cap DESC
        )),
    --
    ('Google market_cap includes both of their securities',
      (
      SELECT
        market_cap_usd
      FROM
        `sixty_securities.securities`,
        UNNEST(ts)
      WHERE
        name LIKE 'Alphabet%'
        AND date = '2018-08-01') BETWEEN 7.9e11
      AND 8e11),
    --
    ('All security types are included',
      (
      SELECT
        count (DISTINCT type)
      FROM
        `sixty_securities.securities_all`
      WHERE
        type IN ('Share/Common/Ordinary',
          -- sometimes called 'Preferred'
          'Preferred Equity',
          'American Depositary Receipt',
          'Global Depositary Receipt',
          'Exchange Traded Fund (ETF-ETF)' ) ) = 5),
    --
    ('Includes Vale ADR Common, which is a close race in the most tradeable, and Roseneft GDR as Russia not tradeable',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.securities`
      WHERE
        fsym_listing_id IN ('L505VS-L',
          'GMB65V-L')) = 2),
    --
    ('Includes Henkel Common rather than Pref, even though the Pref has a longer history',
      (
      SELECT
        COUNT(*) = 1
      FROM
        `sixty_securities.securities_all`
      WHERE
        fsym_security_id = 'MCP8JW-S')),
    --
    ('Includes correct entity ids',
      (
      SELECT
        COUNT(*) = 3
      FROM
        `sixty_securities.companies`
      WHERE
        factset_entity_id IN (
          -- Dr Pepper
          '0HYK76-E',
          -- Lloyds
          '07JRZL-E',
          -- Workday
          '06ZK05-E' ))),
    --
    ('Includes both Workday securities',
      (
      SELECT
        COUNT(*) = 2
      FROM
        `sixty_securities.companies`,
        UNNEST(securities)
      WHERE
        fsym_id IN ( 'MS9VJJ-S',
          'W4DVJH-S' ))),
    --
    ('Selects the Lukoil security and regional that is not traded on the US OTC markets, despite less history',
      (
      SELECT
        LEAST(fsym_id='BQQDG2-R', fsym_listing_id = 'W25L8B-L')
      FROM
        `sixty_securities.securities`
      WHERE
        factset_entity_id = '05HQZG-E')),
    --
    ('Australia has ISINs',
      (
      SELECT
        COUNT(isin)
      FROM
        `sixty_securities.securities`
      WHERE
        fsym_id = 'H1PZ83-R'
        AND isin IS NOT NULL ) = 1),
    --
    ('Caterpiller has dates on US holidays',
      (
      SELECT
        COUNT(date)
      FROM
        `sixty_securities.securities`,
        UNNEST(ts) ts
      WHERE
        fsym_id = 'PY5KHK-R'
        AND date = '2016-01-01') = 1 ),
    --
    ('Fortescue initial volume flows through, despite not having valid prices at this point',
      (
      SELECT
        SUM(volume_usd)
      FROM
        `sixty_securities.securities`,
        UNNEST(ts)
      WHERE
        fsym_id = 'TQ3TPS-R'
        AND date BETWEEN '1993-04-01'
        AND '1993-06-01') > 10 ),
    --
    ('Important ts fields all have values for Verizon',
      (
      SELECT
        LEAST( COUNTIF(RETURNS IS NOT NULL), COUNTIF(price_open IS NOT NULL), COUNTIF(shares_outstanding IS NOT NULL), COUNTIF(market_cap IS NOT NULL), COUNTIF(liquidity IS NOT NULL) )
      FROM
        `sixty_securities.securities`,
        UNNEST(ts)
      WHERE
        fsym_listing_id = 'JZTDC0-L') > 5000),
    --
    ('Non-nullable columns do not have nulls',
      (
      SELECT
        GREATEST( COUNTIF(is_universe IS NULL), COUNTIF(is_tradeable IS NULL) )
      FROM
        `sixty_securities.securities_all`,
        UNNEST(ts) ) =0),
    --
    ( 'No stocks in universe without market cap',
      (
      SELECT
        (
        SELECT
          COUNT(*)
        FROM
          `sixty_securities.securities_all`,
          UNNEST(ts)
        WHERE
          is_universe
          AND market_cap IS NULL
          AND type = 'Share/Common/Ordinary') = 0)),
    --
    ( 'securities_all has approx correct number of securities',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.securities_all`) BETWEEN 5e4
      AND 5e5),
    --
    --
    ( 'securities_all has same number of companies as companies table (except for those without regionals)',
      ((
        SELECT
          COUNT(*)
        FROM
          `sixty_securities.securities_all`)) = (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.companies`
      WHERE
        EXISTS (
        SELECT
          *
        FROM
          UNNEST(securities),
          UNNEST(regionals)) )),
    --
    ( 'top countries all have stocks with ts',
      (
      SELECT
        count (DISTINCT exchange.country_iso)
      FROM
        `sixty_securities.securities_all`
      WHERE
        ARRAY_LENGTH(ts) > 0
        AND exchange.country_iso IN ('US',
          'JP',
          'CN',
          'GB',
          'CA',
          'KR',
          'TW',
          'HK',
          'IN',
          'AU',
          'DE',
          'FR',
          'MY',
          'SG',
          'SE',
          'ZA',
          'IT',
          'NO',
          'PL',
          'CH')) = 20 ),
    --
    ( 'Oracle is not tradeable on July 4 holiday',
      (
      SELECT
        LOGICAL_AND(is_valid_price )
      FROM
        `sixty_securities.securities_all`,
        UNNEST(ts)
      WHERE
        fsym_id = 'HQ4DBK-R'
        AND date = '2018-07-04')),
    --
    ( 'Oracle is constantly valid since 1988',
      (
      SELECT
        LOGICAL_AND(is_valid_price )
      FROM
        `sixty_securities.securities_all`,
        UNNEST(ts)
      WHERE
        fsym_id = 'HQ4DBK-R'
        AND date BETWEEN '1988-01-01'
        AND '2018-01-01')),
    --
    ( 'Oracle was not tradeable all the days prior to 1988',
      (
      SELECT
        LOGICAL_AND(is_tradeable ) IS FALSE
      FROM
        `sixty_securities.securities_all`,
        UNNEST(ts)
      WHERE
        fsym_id = 'HQ4DBK-R'
        AND date < '1988-01-01') ),
    --
    ( 'Dead company (iFinix) does not have market cap filled forward',
      (
      SELECT
        COUNTIF( market_cap IS NOT NULL) = 0
      FROM
        `sixty_securities.securities_all`,
        UNNEST(ts)
      WHERE
        fsym_id = 'T9PZQM-R'
        AND date BETWEEN '2015-12-01'
        AND '2018-01-01' ) ),
    --
    ('Peabody has the post-bankrupcy regional',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.securities_all`
      WHERE
        fsym_regional_id = 'MSD481-R') = 1 ),
    --
    ('Oracle has geo_code of AM',
      (
      SELECT
        company.geo_code
      FROM
        `sixty_securities.securities_all`
      WHERE
        fsym_id = 'HQ4DBK-R') = 'AM' ),
    --
    ('No null geo_codes',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.securities_all`
      WHERE
        company.geo_code IS NULL) = 0 ),
    --
    ('Microsoft has correct ticker',
      (
      SELECT
        ticker
      FROM
        `sixty_securities.companies`,
        UNNEST(securities),
        UNNEST(regionals) r
      WHERE
        r.fsym_id = 'P8R3C2-R' ) = 'MSFT' ),
    --
    ('No duplicate tickers within an region',
      (
      SELECT
        COUNT(*)
      FROM
        `sixty_securities.companies`,
        UNNEST(securities),
        UNNEST(regionals)
      WHERE
        ticker_region IS NOT NULL
      GROUP BY
        ticker_region
      ORDER BY
        1 DESC
      LIMIT
        1) = 1 ),
    --
    ('price_close is null on zero-volume days',
      (
      SELECT
        price_close IS NULL
        AND price IS NOT NULL
      FROM
        `sixty_securities.securities_all`,
        UNNEST(ts)
      WHERE
        fsym_id = 'CN458N-R'
        AND date = '2019-04-26' ) IS TRUE ),
    --
    ('No exchanges have large changes in listings count between consecutive days',
      (
      WITH
        exchange_counts AS (
        SELECT
          exchange.country,
          date,
          COUNT(*) ct
        FROM
          `sixty_securities.securities`,
          UNNEST(ts)
        GROUP BY
          1,
          2),
        changes AS (
        SELECT
          country,
          date,
          ct,
          LN(ct / LAG(ct,1) OVER (PARTITION BY country ORDER BY date )) AS proportion_change
        FROM
          exchange_counts
        WHERE
          date > '2005-01-01'
          -- too few and the distribution of the proportions is different
          AND ct > 50 )
      SELECT
        MAX(ABS(proportion_change))
      FROM
        changes ) < 0.25 )
    --
    ])