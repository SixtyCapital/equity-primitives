select * from unnest([
'US',
'DE',
'CA',
'GB',
'AU',
'CN',
'IN',
'ES',
'JP',
'HK',
'FR',
'CH',
'SE',
'KR',
'TH',
'LU',
'RU',
'TW',
'IT',
'NL',
'SG',
'MX',
'MY',
'BR',
'PL',
'ZA',
'IE',
'IL',
'ID',
'AT',
'NO',
'CL',
'DK',
'TR',
'BE',
'GR',
'PE',
'FI',
'NZ',
'PH',
'AR',
'BG',
'EG',
'PT',
'HR',
'KW',
'SA',
'NG',
'AE',
'CO',
'CZ',
'SK',
'MA',
'HU',
'SI',
'IS'
]) as country_iso


-- script for changing this:

-- get the number of securities listed by country and their description, as a starter list
-- ```python
-- import sixty
-- import pandas as pd
-- from sixty.hooks.gbq import read_gbq
-- query = """
-- SELECT
--   COUNT(*) AS ct,
--   country_desc,
--   exchange.country_iso
-- FROM
--   `sixty-capital.sixty_listings.listings`
-- JOIN
--   `factset_ref.country_map`f
-- ON
--   exchange.country_iso = f.iso_country
-- GROUP BY
--   2,
--   3
-- ORDER BY
--   1 DESC
-- """
-- df = read_gbq(query)
-- print(df.to_dict(orient='rows'))
-- ```

-- Then copy and paste the result so you can comment out the rows manually: (sample):

-- countries = (
-- [{'country_desc': u'United States', 'country_iso': u'US', 'ct': 310565},
--  {'country_desc': u'Germany', 'country_iso': u'DE', 'ct': 164918},
--  {'country_desc': u'Canada', 'country_iso': u'CA', 'ct': 87682},
--  {'country_desc': u'United Kingdom', 'country_iso': u'GB', 'ct': 54999},
--  {'country_desc': u'Australia', 'country_iso': u'AU', 'ct': 22178},
--  {'country_desc': u'India', 'country_iso': u'IN', 'ct': 13360},
--  {'country_desc': u'Spain', 'country_iso': u'ES', 'ct': 8641},
--  {'country_desc': u'Japan', 'country_iso': u'JP', 'ct': 7630},
-- #  {'country_desc': u'China', 'country_iso': u'CN', 'ct': 5952},

-- Then to generate the query:
-- ```python
-- countries = list( pd.DataFrame(countries).country_iso)
-- print("select * from unnest([")
-- for country in countries[:-1]:
--     print("'{}',".format(country))
-- print "'{}'".format(countries[-1]) # sql commas ftw
-- print("]) as country_iso")
-- ```

-- To get the current numbers, you can run:

-- SELECT
--   listing.exchange.country_iso,
--   country_desc,
--   COUNTIF(listing.listing.fsym_id IS NOT NULL) AS listings_count,
--   COUNTIF(securities.fsym_id IS NOT NULL) AS securities_count
-- FROM
--   `sixty_listings.listings` listing
-- JOIN
--   `factset_ref.country_map`f
-- ON
--   exchange.country_iso = f.iso_country
-- LEFT JOIN
--   `sixty_securities.securities` securities
-- ON
--   securities.fsym_id = listing.fsym_regional_id
-- GROUP BY
--   1,
--   2
-- ORDER BY
--   3 DESC