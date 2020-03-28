WITH
  -- no need to be temporal here - that's on the company side. We do pull the
  -- latest, because sometimes the descriptions change very slightly
  temporal AS (
  SELECT
    *,
    parse_DATE('%Y%m%d',
      _table_suffix) date
  FROM
    `revere_industry.RBICS_STRUCTURE_L6__*` ),
  latest AS (
  SELECT
    L6_ID,
    MAX(date) date
  FROM
    temporal
  GROUP BY
    L6_ID )
SELECT
  l6_id,
  ARRAY<STRUCT<level string,
  ID int64,
  name string>> [ ('1',
    L1_ID,
    L1_NAME),
  ('2',
    L2_ID,
    L2_NAME),
  ('3',
    L3_ID,
    L3_NAME),
  ('4',
    L4_ID,
    L4_NAME),
  ('5',
    L5_ID,
    L5_NAME),
  ('6',
    L6_ID,
    L6_NAME) ] industry
FROM
  temporal
JOIN
  latest
USING
  (date,
    l6_id)