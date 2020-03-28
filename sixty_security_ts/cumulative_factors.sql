WITH
  splits AS (
  SELECT
    * EXCEPT (p_split_date),
    p_split_date AS date
  FROM
    `factset_prices_v2.fp_basic_splits`),
  dividends_spinoff AS (
    -- these dividends adjust the price, as though they're reinvested
    -- e.g. if the company hits zero the next day, its return will be zero even with a large value here
  SELECT
    p_divs_exdate AS date,
    fsym_id,
    SUM(p_divs_pd) dividend_spinoff
  FROM
    `factset_prices_v2.fp_basic_dividends`
  WHERE
    p_divs_s_spinoff = TRUE
  GROUP BY
    fsym_id,
    date ),
  dividends_cash AS (
    -- these dividends are added as cash rather than a factor applied to shares
    -- they're added to the price later in a fixed cash amount
    -- e.g. if the company hits zero the next day, its return will include the cash here
  SELECT
    p_divs_exdate AS date,
    fsym_id,
    SUM(p_divs_pd) dividend_cash
  FROM
    `factset_prices_v2.fp_basic_dividends`
  WHERE
    p_divs_s_spinoff = FALSE
  GROUP BY
    fsym_id,
    date ),
  prev_prices AS (
  SELECT
    p_date AS date,
    fsym_id,
    LAG(P_PRICE, 1) OVER (PARTITION BY fsym_id ORDER BY p_date) AS prev_price
  FROM
    `factset_prices_v2.fp_basic_prices` ),
  factors AS (
  SELECT
    fsym_id,
    ARRAY_AGG((
      SELECT
        AS STRUCT date,
        P_SPLIT_FACTOR AS split_factor,
        dividend_cash / prev_prices.prev_price AS cash_dividend_return,
        IF (dividend_spinoff>= prev_prices.prev_price,
          NULL,
          (prev_prices.prev_price - dividend_spinoff) / prev_prices.prev_price) AS spinoff_dividend_factor )) ts
  FROM
    prev_prices
  FULL JOIN
    splits
  USING
    (date,
      fsym_id )
  FULL JOIN
    dividends_spinoff
  USING
    (date,
      fsym_id )
  FULL JOIN
    dividends_cash
  USING
    (date,
      fsym_id )
  GROUP BY
    fsym_id )
SELECT
  fsym_id,
  ARRAY(
  SELECT
    AS STRUCT date,
    -- if you order the rows by date, you want to include everything that happened after (i.e. below) that date.
    -- So newer data has fewer points included, and older data has more points included
    -- You don't want to include the current point, because that should be on the 'newer' cumulative factor, as the split / spinoff has already happened
    ifnull(EXP(SUM(LN(split_factor)) OVER all_following),
      1) AS cumulative_split_factor,
    ifnull(EXP(SUM(LN(spinoff_dividend_factor)) OVER all_following),
      1) AS cumulative_spinoff_dividend_factor,
    ifnull(cash_dividend_return,
      0) AS cash_dividend_return
  FROM
    UNNEST(dates_all.date) date
  LEFT JOIN
    UNNEST(factors.ts)
  USING
    (date)
  WINDOW
    all_following AS (
    ORDER BY
      DATE ROWS BETWEEN 1 FOLLOWING
      AND UNBOUNDED FOLLOWING )) ts
FROM
  `sixty_security_ts.security_dates` dates_all
JOIN
  factors
USING
  ( fsym_id)