WITH
  company_factset AS (
  SELECT
    COMPANY_ID,
    FS_ENTITY_ID,
    parse_DATE('%Y%m%d',
      _table_suffix) date
  FROM
    `revere_industry.COMPANY_FACTSET__*` ),
  aggregated AS (
  SELECT
    c.*,
    f.fs_entity_id AS factset_entity_id,
    i.industry,
    l6_id,
    parse_DATE('%Y%m%d',
      c._table_suffix) date,
    # to remove duplicates
    ROW_NUMBER() OVER (PARTITION BY f.FS_ENTITY_ID, f._table_suffix ORDER BY LENGTH(cusip),
      LENGTH(c.name)) AS priority
  FROM
    `revere_industry.COMPANY__*` AS c
  JOIN
    `revere_industry.COMPANY_FACTSET__*` AS f
  ON
    c.ID = f.COMPANY_ID
    AND c._table_suffix = f._table_suffix
  JOIN
    `revere_industry.COMPANY_RBICS_FOCUS_L6__*` AS r
  ON
    c.ID = r.COMPANY_ID
    AND c._table_suffix = r._table_suffix
  JOIN
    `revere_industry.industry` AS i
  ON
    RBICS2_L6_ID = l6_id
  WHERE
    cusip IS NOT NULL ),
  nested AS (
  SELECT
    factset_entity_id,
    ARRAY_AGG(STRUCT(DATE_TRUNC(date, year) AS year,
        date,
        l6_id,
        industry)
    ORDER BY
      date) ts
  FROM
    aggregated
  WHERE
    priority = 1
  GROUP BY
    factset_entity_id)
SELECT
  nested.*,
  (
  SELECT
    AS STRUCT *
  FROM
    UNNEST(ts)
  ORDER BY
    date DESC
  LIMIT
    1) AS latest
FROM
  nested