  -- All vendor data on securities that are in our universe - namely they were at some point decent liquidity, and are the right type of security, and are in a universe country
SELECT
  *
FROM
  `sixty_securities.securities_all`
WHERE
  (
  SELECT
    COUNTIF(is_universe) > 0
  FROM
    UNNEST(ts))