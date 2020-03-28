WITH
  flattened AS (
  SELECT
    l6_id,
    industry.*
  FROM
    `revere_industry.industry` i,
    UNNEST(industry) industry )
SELECT
  target.l6_id,
  comparison.l6_id AS comparison_l6_id,
  COUNT(comparison.l6_id) AS overlap_count
FROM
  flattened AS target
JOIN
  flattened AS comparison
USING
  (id)
GROUP BY
  l6_id,
  comparison_l6_id
ORDER BY
  overlap_count DESC
