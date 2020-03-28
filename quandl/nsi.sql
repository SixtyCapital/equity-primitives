-- TODO: currently broken
WITH
  companies AS (
  SELECT
    DISTINCT fsym_regional_id,
    code,
    fsym_id
  FROM
    `quandl.news_data`
  JOIN
    `sixty_listings.listings`
  ON
    REPLACE(code, "_", "-") = ticker_region ),
  nested AS (
  SELECT
    code,
    ARRAY_AGG((
      SELECT
        AS STRUCT news.* EXCEPT (code) )
    ORDER BY
      date) ts
  FROM
    `quandl.news_data` news
  GROUP BY
    code)
SELECT
  * EXCEPT (code)
FROM
  companies
JOIN
  nested
USING
  (code)