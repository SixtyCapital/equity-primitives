SELECT
  *
FROM
  UNNEST(ARRAY<STRUCT<test string, result bool >> [ ( 'AUD vs USD has low average, so interest rates are of the right magnitude ',
      (
      SELECT
        (
        SELECT
          ABS(AVG(returns_excess))
        FROM
          UNNEST(ts)
        WHERE
          date BETWEEN '2010-12-01'
          AND '2017-03-01' )
      FROM
        `sixty_macro.currency_returns`
      WHERE
        base_currency = 'AUD'
        AND quote_currency = 'USD') < 0.0001 ), ( 'JPY went down in 2012/2013',
      (
      SELECT
        (
        SELECT
          SUM(returns_excess)
        FROM
          UNNEST(ts)
        WHERE
          date BETWEEN '2012-12-01'
          AND '2013-03-01' )
      FROM
        `sixty_macro.currency_returns`
      WHERE
        base_currency = 'JPY'
        AND quote_currency = 'USD') < 0 )])
