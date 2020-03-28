-- # TODO: Delete, as moved to investment
SELECT
  equity.fsym_id,
  ARRAY(
  SELECT
    AS STRUCT equity_ts.date,
    equity_ts.return_excess,
    index_ts.return_excess AS index_return,
    -- this is making too much zero - should only be treated as zero if between dates
    ifnull(equity_ts.return_excess,
      0) - (risk_ts.country_beta * index_ts.return_excess) AS return_equity_hedged,
    risk_ts.country_beta,
    risk_ts.risk_expected
  FROM
    UNNEST(equity.ts) equity_ts
  JOIN
    UNNEST(index.ts) index_ts
  ON
    equity_ts.date = index_ts.date
  JOIN
    UNNEST(risk_ts.risk_ts) risk_ts
  ON
    equity_ts.date = risk_ts.date
  ORDER BY
    equity_ts.date ) ts
FROM
  `sixty_security_ts.security_ts` equity
JOIN
  `risk_pca.risk_ts` risk_ts
ON
  equity.fsym_id = risk_ts.fsym_id
JOIN
  `sixty_macro.country_index` country
ON
  risk_ts.country_iso = country.country_iso
JOIN
  `sixty_security_ts.security_ts` index
ON
  index.fsym_id = country.fsym_id
