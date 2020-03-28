SELECT
  DISTINCT parse_DATE('%Y%m%d',
    _table_suffix) AS date,
  parse_DATE('%Y%m%d',
    effective_date ) AS effective_date,
  * EXCEPT ( effective_date )
FROM
  `sp_index.ADJSDC_*`