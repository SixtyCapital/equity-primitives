WITH
  returns_total AS (
  SELECT
    fsym_id,
    ARRAY(
    SELECT
      AS STRUCT date,
      -- if it's not a current date, null the return (can't do WHERE clause as need the prev value regardless of validity)
      IF(is_current_price,
        price_adjusted / LAG(price_adjusted, 1) OVER (ORDER BY date) - 1 + cash_dividend_return,
        NULL) AS return_total,
      -- for very large moves, this calc is dependent on exactly how you finance the usd
      IF(is_current_price,
        price_adjusted_usd / LAG(price_adjusted_usd, 1) OVER (ORDER BY date) - 1 + cash_dividend_return,
        NULL) AS return_usd,
      -- TODO: add interest rate to close_to_open and change these (/ add) excess returns
      IF(is_current_price,
        price_open_adjusted / LAG(price_adjusted, 1) OVER (ORDER BY date) - 1 + cash_dividend_return,
        NULL) AS return_total_close_to_open,
      IF(is_current_price,
        price_adjusted / price_open_adjusted - 1,
        NULL) AS return_total_open_to_close
    FROM
      UNNEST(prices.ts)) ts
  FROM
    `sixty_security_ts.prices` prices )
SELECT
  fsym_id,
  ARRAY(
  SELECT
    AS STRUCT *,
    return_total - (interest_rate / 252) AS return_excess,
    -- synonym 
    return_total - (interest_rate / 252) AS RETURNS,
    return_total_close_to_open - (interest_rate / 252) AS return_excess_close_to_open,
    -- (it's the same)
    return_total_open_to_close AS return_excess_open_to_close,
    -- not 100% sure this is the correct order of operations
    -- I think instead we should compound the total return, and then substract the cash rate. Need to code and test that carefully
    EXP(SUM(LN(GREATEST(1 + return_total - (interest_rate / 252), 0.01))) OVER (ORDER BY date)) AS return_excess_index
  FROM
    UNNEST(prices.ts) prices_ts
  LEFT JOIN
    UNNEST(returns_total.ts)
  USING
    (date)
  LEFT JOIN
    UNNEST(interest_rates.ts) ir_ts
  USING
    (date) ) ts
FROM
  `sixty_security_ts.prices` prices
LEFT JOIN
  returns_total
USING
  (fsym_id)
LEFT JOIN
  `sixty_macro.interest_rates` interest_rates
USING
  (currency)