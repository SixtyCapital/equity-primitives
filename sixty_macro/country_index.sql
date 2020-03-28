-- for x in sixty.model.country_index.country_to_equity_index.items():
--     print "select '{}' as country_iso, '{}' as fs_perm_sec_id".format(x[0], x[1])
--     print("UNION ALL")
-- or from json as s:
-- In [8]: d=json.loads(s)
-- In [9]: for x in d:
--    ...:     print "select '{country_iso}' as country_iso, '{fs_perm_sec_id}' as fs_perm_sec_id, '{fsym_regional_id}' as fsym_id".format(**x)
--    ...:     print("UNION ALL")
-- HK previously 'PD6VW6-S-HK', but that has less history and does NOT have shares_outstanding info
select 'JP' as country_iso, 'NYPTNY-R' as fsym_id
UNION ALL
select 'BR' as country_iso, 'SB2GSJ-R' as fsym_id
UNION ALL
select 'CA' as country_iso, 'XP3D8X-R' as fsym_id
UNION ALL
select 'FR' as country_iso, 'NSZ72C-R' as fsym_id
UNION ALL
select 'DE' as country_iso, 'G7Y4VJ-R' as fsym_id
UNION ALL
select 'NO' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'IT' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'PT' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'BE' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'ES' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'DK' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'FI' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'SE' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'AT' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'NL' as country_iso, 'SPC0FK-R' as fsym_id
UNION ALL
select 'AU' as country_iso, 'RQSY8V-R' as fsym_id
UNION ALL
select 'HK' as country_iso, 'TG7CGC-R' as fsym_id
UNION ALL
select 'SG' as country_iso, 'RXJL2K-R' as fsym_id
UNION ALL
select 'KR' as country_iso, 'TG8977-R' as fsym_id
UNION ALL
select 'CH' as country_iso, 'DTJPMR-R' as fsym_id
UNION ALL
select 'ZA' as country_iso, 'Q0J84S-R' as fsym_id
UNION ALL
select 'US' as country_iso, 'M75BNK-R' as fsym_id
UNION ALL
select 'GB' as country_iso, 'R96HHB-R' as fsym_id
