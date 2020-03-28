SELECT
  interest_rates_currency.currency,
  ARRAY(
  SELECT
    AS STRUCT date,
    -- exchange rate change
    (exch_rate_usd / LAG(exch_rate_usd, 1) OVER (ORDER BY date)) - 1
    -- interest rate differential. Higher local rate means higher returns
    + (interest_rates_currency.interest_rate - interest_rates_usd.interest_rate) / 252
    --
    AS returns_excess
  FROM
    UNNEST(exchange_rates.ts)
  JOIN
    UNNEST(interest_rates_currency.ts) interest_rates_currency
  USING
    (date)
  JOIN
    UNNEST(interest_rates_usd.ts) interest_rates_usd
  USING
    (date)
  ORDER BY
    date ) ts
FROM
  `sixty_macro.exchange_rates` exchange_rates
JOIN
  `sixty_macro.interest_rates` interest_rates_currency
USING
  (currency)
  -- join this for the USD interest rates only
JOIN
  `sixty_macro.interest_rates` interest_rates_usd
ON
  interest_rates_usd.currency = 'USD'