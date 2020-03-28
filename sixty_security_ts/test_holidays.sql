  -- custom test for the holidays query
  -- Because factest backfills data for holidays, we've had to create
  -- a 'mock_prices' table with an example table for what we'd receive on 2018-04-02
  -- We then run the logic in `security_dates` and check that 2018-04-02 is there for
  -- a UK security
WITH
  start_end_non_holiday_dates AS (
  SELECT
    fsym_id,
    fref_listing_exchange AS exchange,
    MIN(p_date) AS date_start,
    MAX(p_date) AS date_end
  FROM
    -- mocking prices
    (
    SELECT
      *
    FROM
      `factset_prices_v2.fp_basic_prices`
    WHERE
      p_volume > 0
      AND p_date <= '2018-04-02' )
    -- end mock
  JOIN
    `factset_sym.sym_coverage`
  USING
    (fsym_id)
  GROUP BY
    fsym_id,
    exchange),
  -- the holidays for every security, from a table that has holidays by currency
  start_end_dates AS (
  SELECT
    fsym_id,
    -- we group by fsym_id and take the min & max here on the small chance than a regional has multiple currencies
    -- this could create a small logical mistake (adding dates that potentially don't exist)
    -- but it's protecting downstream queries from doing repeated exploading joins, and the logic mistake is very small
    MIN(date_start) date_start,
    -- last date from either the standard table or eligible holidays
    MAX(GREATEST( holiday_net.date_end,(
        SELECT
          MAX(date)
        FROM
          UNNEST(date) date
        WHERE
          -- holidays since the security's start, and within eight days of the most recent date
          -- need to add on the five days because the day before a holiday we won't have the date; this is like a conditional limit fill forward
          -- we previously used five, but JP can have four holidays over new year, and weekends pushed it over the five
          date < DATE_ADD(date_end, INTERVAL 8 day) ))) date_end
  FROM
    start_end_non_holiday_dates AS holiday_net
  JOIN
    -- mocking holidays
    (
    SELECT
      exchange,
      ARRAY((
        SELECT
          date
        FROM
          UNNEST(date) date
        WHERE
          date <= '2018-04-02')) date
    FROM
      `sixty_security_ts.holidays`)
    -- end mock
  USING
    (exchange)
  GROUP BY
    fsym_id)
SELECT
  date_end = '2018-04-02'
FROM
  start_end_dates
WHERE
  -- Vodafone, which is a UK security and so had a holiday on Apr 2nd
  fsym_id = 'J4RDQ3-R'