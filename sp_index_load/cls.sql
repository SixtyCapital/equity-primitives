WITH
  raw AS (
  SELECT
    DISTINCT parse_DATE('%Y%m%d',
      _table_suffix) AS date,
    parse_DATE('%Y%m%d',
      effective_date ) AS effective_date,
    * EXCEPT ( effective_date )
  FROM
    `sp_index.CLSSDC_*` ),
  -- backfills over holidays
  -- we backfill by finding the last observed date for each date
  -- this is more verbose than usual, becaues we don't want to LAST_VALUE every column
  -- we also can't LAST_VALUE the array, because the memory blows up
  nested_raw AS (
  SELECT
    date,
    index_code,
    ARRAY_AGG((
      SELECT
        AS STRUCT raw.* EXCEPT (date,
          index_code))) cs
  FROM
    raw
  GROUP BY
    1,
    2 ),
  all_dates AS (
  SELECT
    index_code,
    GENERATE_DATE_ARRAY(MIN(date), MAX(date)) date
  FROM
    nested_raw
  GROUP BY
    index_code),
  date_asofs AS (
  SELECT
    index_code,
    -- the date of the actual holding, even if no observations
    date AS date_asof,
    LAST_VALUE(nested_raw.date IGNORE NULLS) OVER (PARTITION BY index_code ORDER BY date ) AS date
  FROM
    all_dates,
    UNNEST(date) date
  LEFT JOIN
    nested_raw
  USING
    (date,
      index_code)
  WHERE
    EXTRACT(dayofweek
    FROM
      date) BETWEEN 2
    AND 6 )
SELECT
  index_code,
  -- we use date, so convert back
  date_asof AS date,
  cs.*
FROM
  date_asofs
JOIN ( nested_raw
  CROSS JOIN
    UNNEST(cs) cs)
USING
  (date,
    index_code)