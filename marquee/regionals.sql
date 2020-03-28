-- because there are a lot of duplicates and this is joined downstream, we ensure there's only one row per sedol
SELECT
  sedol,
  ARRAY_AGG((
    SELECT
      AS STRUCT bbid,
      bcid,
      gsid,
      name,
      assetClassificationsGicsSector AS gics_sector,
      assetClassificationsGicsIndustryGroup AS gics_industry_group,
      assetClassificationsGicsIndustry AS gics_industry,
      assetClassificationsGicsSubIndustry AS gics_sub_industry,
      assetClassificationsIsPrimary = 'true' AS is_primary,
      listed = 'true' AS is_listed )
  ORDER BY
    assetClassificationsIsPrimary = 'true' DESC, listed = 'true' DESC )[safe_ORDINAL(1)].*
FROM
  `sixty-capital-ext.marquee.single_stock_extract`
WHERE
  sedol IS NOT NULL
GROUP BY
  1