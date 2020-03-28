  -- TODO: this is awkwardly reliant on `sixty_securities.companies`
  -- I think a better model is to run a cleaning on this that doesn't
  -- rely on sixty data, and then pull the data in in `sixty_securities.securities`
WITH
  nested AS (
  SELECT
    code as ticker,
    ARRAY_AGG((
      SELECT
        AS STRUCT vol.* EXCEPT (code) )
    ORDER BY
      date) ts
  FROM
    `quandl.vol_data` vol
  GROUP BY
    code)
SELECT
  regional.fsym_id,
  ts
FROM
  `sixty_securities.companies`,
  UNNEST(securities),
  UNNEST(regionals) regional
JOIN
  nested
USING
  (ticker)
WHERE
  region_from_ticker = 'US'