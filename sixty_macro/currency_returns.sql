  -- every currency to every currency. About 100x bigger than `currency_returns_usd`, but convenient when needed
CREATE OR REPLACE TABLE
  `sixty_macro.currency_returns`
PARTITION BY
  _pseudo_partition
CLUSTER BY
  quote_currency,
  base_currency AS (
  SELECT
    quote.currency AS quote_currency,
    base.currency AS base_currency,
    ARRAY(
    SELECT
      AS STRUCT date,
      -- the position is long base financed in quote, so this needs to be a multiplicative combination
      -- (i.e. if one doubled and the other halved, the return would be 4x, not 2.5x)
      EXP(LOG(1+ base.returns_excess) - LOG(1+ quote.returns_excess)) -1 AS returns_excess
    FROM
      UNNEST(quote.ts) quote
    JOIN
      UNNEST(base.ts) base
    USING
      (date)) ts,
    CAST( '1970-01-01' AS date) AS _pseudo_partition
  FROM
    `sixty_macro.currency_returns_usd` AS base
  CROSS JOIN
    `sixty_macro.currency_returns_usd` AS quote)