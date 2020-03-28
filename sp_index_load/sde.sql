SELECT
  DISTINCT parse_DATE('%Y%m%d',
    _table_suffix) AS date,
  parse_DATE('%Y%m%d',
    last_updated_date ) AS last_updated_date,
  parse_DATE('%Y%m%d',
    close_of_business_date ) AS close_of_business_date,
  parse_DATE('%Y%m%d',
    effective_date ) AS effective_date,
  * EXCEPT (last_updated_date,
    close_of_business_date,
    effective_date )
FROM
  `sp_index.SDE_*`