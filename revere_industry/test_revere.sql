SELECT
  *
FROM
  UNNEST(ARRAY<STRUCT<test string, result bool>> [ ( 'no duplicate companies on any date',
      (
      SELECT
        COUNT(*)
      FROM (
        SELECT
          factset_entity_id
        FROM
          `revere_industry.company_industry` d,
          UNNEST(ts)
        GROUP BY
          factset_entity_id,
          date
        HAVING
          COUNT(*) > 1)) = 0) ])
