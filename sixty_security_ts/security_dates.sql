WITH
  -- start and end dates from the standard table, no holidays yet
  start_end_non_holiday_dates AS (
  SELECT
    fsym_id,
    fref_listing_exchange AS exchange,
    MIN(p_date) AS date_start,
    MAX(p_date) AS date_end
  FROM
    `factset_prices_v2.fp_basic_prices`
  JOIN
    `factset_sym.sym_coverage`
  USING
    (fsym_id)
  GROUP BY
    fsym_id,
    exchange),
  -- the holidays for every security, from a table that has holidays by exchange
  start_end_dates AS (
  SELECT
    fsym_id,
    -- we group by fsym_id and take the min & max here on the small chance than
    -- a regional has multiple currencies this could create a small logical
    -- mistake (adding dates that potentially don't exist) but the upside is
    -- protecting downstream queries from doing repeated exploading joins, and
    -- the downside added logic mistake is very small
    MIN(date_start) date_start,
    -- last date from either the standard table or eligible holidays
    MAX(GREATEST( holiday_net.date_end,(
        SELECT
          MAX(date)
        FROM
          UNNEST(date) date
        WHERE
          -- Within ten days of the most recent
          -- date. Need to allow for a buffer because the day before a holiday we won't have
          -- the date; this is like a conditional limit fill forward. We previously used
          -- five, but JP can have four holidays over new year, and weekends pushed it
          -- over the five, and then they changed Emperor, and that was a whole week plus
          -- weekends. An argument against monarchies if I ever heard one
          --
          -- An alternative option is to ensure the holidays are contiguous, but this
          -- is more complicated logic,
          -- and all vastly inferior to an actual holiday calendar
          DATE_DIFF( date, date_end, day) <= 12 ))) date_end
  FROM
    start_end_non_holiday_dates AS holiday_net
  JOIN
    `sixty_security_ts.holidays`
  USING
    (exchange)
  GROUP BY
    fsym_id)
SELECT
  fsym_id,
  ARRAY(
  SELECT
    date
  FROM
    UNNEST(GENERATE_DATE_ARRAY(date_start, date_end)) AS date
  WHERE
    EXTRACT(dayofweek
    FROM
      date) BETWEEN 2
    AND 6 ) date
FROM
  start_end_dates