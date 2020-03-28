SELECT
  DISTINCT parse_DATE('%Y%m%d',
    _table_suffix) AS date,
  parse_DATE('%Y%m%d',
    date_of_index ) AS date_of_index,
  * EXCEPT ( date_of_index)
FROM
  `sp_index.SDL_*`