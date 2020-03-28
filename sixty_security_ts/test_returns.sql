  -- wrong name but the dataset should be renamed anyway; maybe to returns
SELECT
  *
FROM
  UNNEST(ARRAY<STRUCT<test string, result bool>> [
    --
    ( 'verizon split correct',
      (
      SELECT
        ABS(return_excess - 0.00231812) < 0.00000001
      FROM
        `sixty_security_ts.returns`,
        UNNEST(ts) AS ts
      WHERE
        fsym_id = 'FT8FQW-R'
        AND ts.date = '1990-05-02')),
    --
    ( 'verizon regular dividend correct',
      (
      SELECT
        ABS(return_excess + 0.0155548) < 0.00000001
      FROM
        `sixty_security_ts.returns`,
        UNNEST(ts) AS ts
      WHERE
        fsym_id = 'FT8FQW-R'
        AND ts.date = '2010-04-07') ),
    --
    ('verizon special dividend correct',
      (
      SELECT
        ABS(return_excess - 0.01999860) < 0.00000001
      FROM
        `sixty_security_ts.returns`,
        UNNEST(ts) AS ts
      WHERE
        fsym_id = 'FT8FQW-R'
        AND ts.date = '2010-07-02')),
    --
    ( 'UK has holiday on April 2nd 2018',
      (
      SELECT
        COUNT(date) = 1
      FROM
        `sixty_security_ts.holidays`,
        UNNEST(date) date
      WHERE
        exchange = 'LON'
        AND date = '2018-04-02')),
    --
    ( 'UK does not have holiday on 2018-04-03',
      (
      SELECT
        COUNT(date) = 0
      FROM
        `sixty_security_ts.holidays`,
        UNNEST(date) date
      WHERE
        exchange = 'LON'
        AND date = '2018-04-03')),
    --
    ( 'US has holiday on 1986-03-28',
      (
      SELECT
        COUNT(date) = 1
      FROM
        `sixty_security_ts.holidays`,
        UNNEST(date) date
      WHERE
        exchange = 'NYS'
        AND date = '1986-03-28')),
    --
    ('Non-nullable columns do not have nulls',
      (
      SELECT
        GREATEST( COUNTIF(is_current_price IS NULL),COUNTIF(is_valid_price IS NULL), COUNTIF(is_holiday IS NULL) )
      FROM
        `sixty_security_ts.security_ts`,
        UNNEST(ts) ) =0),
    --
    ( 'Oracle has false is_current_price and valid price on a holiday',
      (
      SELECT
        LEAST(is_current_price IS FALSE, is_valid_price IS TRUE)
      FROM
        `sixty_security_ts.security_ts`,
        UNNEST(ts) AS ts
      WHERE
        fsym_id = 'HQ4DBK-R'
        AND date = '1986-03-28') ),
    --
    ( 'Oracle has continuous_price on a holiday',
      (
      SELECT
        price_continuous >0
      FROM
        `sixty_security_ts.security_ts`,
        UNNEST(ts) AS ts
      WHERE
        fsym_id = 'HQ4DBK-R'
        AND date = '1986-03-28') ),
    --
    ( 'No dates before Factset supplies dates',
      (
      SELECT
        COUNT(*) = 0
      FROM
        `sixty_security_ts.security_ts`,
        UNNEST(ts) AS ts
      WHERE
        fsym_id = 'DGB6XN-R'
        AND date < '1990-01-01') ),
    --
    ( 'Random company does not have a valid price just because it is a holiday',
      (
      SELECT
        is_valid_price = FALSE
      FROM
        `sixty_security_ts.security_ts`,
        UNNEST(ts)
      WHERE
        fsym_id = 'M1Q3XR-R'
        AND date = '2017-01-30') ),
    --
    ( 'Toyota is consistently valid since 1991',
      (
      SELECT
        LOGICAL_AND(is_valid_price )
      FROM
        `sixty_security_ts.security_ts`,
        UNNEST(ts)
      WHERE
        fsym_id = 'R2HXLJ-R'
        AND date BETWEEN '1993-01-01'
        AND '2018-01-01')),
    --
    ( 'return does not aggregate with stale prices',
      (
      SELECT
        ts.return_excess IS NULL
      FROM
        `sixty_security_ts.returns`,
        UNNEST(ts) AS ts
      WHERE
        fsym_id = 'VNS1WG-R'
        AND ts.date = '2017-07-10')),
    --
    ( 'KeyCorp (old) dates finish correctly early',
      (
      SELECT
        (
        SELECT
          MAX(date)
        FROM
          UNNEST(ts))
      FROM
        `sixty_security_ts.security_ts`
      WHERE
        fsym_id = 'NQGSHT-R') = '1994-03-01'),
    --
    ( 'Domo has current price on its first day ',
      (
      SELECT
        is_current_price = TRUE
      FROM
        `sixty_security_ts.security_ts`,
        UNNEST(ts)
      WHERE
        fsym_id = 'NJC6GF-R'
        AND date = '2018-06-29' )),
    --
    ( 'No duplicate rows',
      (
      SELECT
        (
        SELECT
          COUNT(*)
        FROM
          `sixty_security_ts.security_ts`
        GROUP BY
          fsym_id
        ORDER BY
          1 DESC
        LIMIT
          1) = 1)),
    --
    ( 'Approximately the correct max rows in ts',
      (
      SELECT
        MAX(ARRAY_LENGTH(ts))
      FROM
        `sixty_security_ts.security_ts`) BETWEEN 8000
      AND 12000)
    --
    ])