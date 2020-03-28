-- this is required because something like:
-- SELECT
-- *
-- FROM
--   `factset_ref.country_map` AS country_map
-- JOIN
--   `reference.country_codes` AS country_codes
-- ON
--   country_map.iso_country = country_codes.ISO3166_1_Alpha_2
-- JOIN
--   `quandl.sge_codes` AS sge_meta
-- ON
--   country_codes.ISO3166_1_Alpha_3 = sge_meta.country_code
--   AND sge_meta.indicator_code = 'IR'
--   where iso_currency = 'USD'

-- ...will find more than one country for a currency, and the
-- interest rates are (weirdly) done by country


-- gbq.read_gbq('select * from `quandl.ir_code_map`')
-- for x in df.values:
--     print "select '{}' as currency, '{}' as code".format(x[0], x[1])
--     print("UNION ALL")
select 'AFN' as currency, 'AFGIR' as code
UNION ALL
select 'AOA' as currency, 'AGOIR' as code
UNION ALL
select 'ALL' as currency, 'ALBIR' as code
UNION ALL
select 'AED' as currency, 'AREIR' as code
UNION ALL
select 'ARS' as currency, 'ARGIR' as code
UNION ALL
select 'AMD' as currency, 'ARMIR' as code
UNION ALL
select 'AUD' as currency, 'AUSIR' as code
UNION ALL
select 'ATS' as currency, 'AUTIR' as code
UNION ALL
select 'AZN' as currency, 'AZEIR' as code
UNION ALL
select 'BIF' as currency, 'BDIIR' as code
UNION ALL
select 'BEF' as currency, 'BELIR' as code
UNION ALL
select 'BDT' as currency, 'BGDIR' as code
UNION ALL
select 'BGN' as currency, 'BGRIR' as code
UNION ALL
select 'BHD' as currency, 'BHRIR' as code
UNION ALL
select 'BSD' as currency, 'BHSIR' as code
UNION ALL
select 'BYR' as currency, 'BLRIR' as code
UNION ALL
select 'BZD' as currency, 'BLZIR' as code
UNION ALL
select 'BOB' as currency, 'BOLIR' as code
UNION ALL
select 'BRL' as currency, 'BRAIR' as code
UNION ALL
select 'BBD' as currency, 'BRBIR' as code
UNION ALL
select 'BND' as currency, 'BRNIR' as code
UNION ALL
select 'BTN' as currency, 'BTNIR' as code
UNION ALL
select 'BWP' as currency, 'BWAIR' as code
UNION ALL
select 'CAD' as currency, 'CANIR' as code
UNION ALL
select 'CHF' as currency, 'CHEIR' as code
UNION ALL
select 'CLP' as currency, 'CHLIR' as code
UNION ALL
select 'CNY' as currency, 'CHNIR' as code
UNION ALL
select 'KMF' as currency, 'COMIR' as code
UNION ALL
select 'CVE' as currency, 'CPVIR' as code
UNION ALL
select 'CRC' as currency, 'CRIIR' as code
UNION ALL
select 'CUP' as currency, 'CUBIR' as code
UNION ALL
select 'CYP' as currency, 'CYPIR' as code
UNION ALL
select 'CZK' as currency, 'CZEIR' as code
UNION ALL
select 'DEM' as currency, 'DEUIR' as code
UNION ALL
select 'DJF' as currency, 'DJIIR' as code
UNION ALL
select 'DKK' as currency, 'DNKIR' as code
UNION ALL
select 'DOP' as currency, 'DOMIR' as code
UNION ALL
select 'ECS' as currency, 'ECUIR' as code
UNION ALL
select 'EGP' as currency, 'EGYIR' as code
UNION ALL
select 'ESP' as currency, 'ESPIR' as code
UNION ALL
select 'EEK' as currency, 'ESTIR' as code
UNION ALL
select 'ETB' as currency, 'ETHIR' as code
UNION ALL
select 'EUR' as currency, 'EURIR' as code
UNION ALL
select 'FIM' as currency, 'FINIR' as code
UNION ALL
select 'FJD' as currency, 'FJIIR' as code
UNION ALL
select 'FRF' as currency, 'FRAIR' as code
UNION ALL
select 'GBP' as currency, 'GBRIR' as code
UNION ALL
select 'GEL' as currency, 'GEOIR' as code
UNION ALL
select 'GHS' as currency, 'GHAIR' as code
UNION ALL
select 'GMD' as currency, 'GMBIR' as code
UNION ALL
select 'GRD' as currency, 'GRCIR' as code
UNION ALL
select 'GTQ' as currency, 'GTMIR' as code
UNION ALL
select 'GYD' as currency, 'GUYIR' as code
UNION ALL
select 'HKD' as currency, 'HKGIR' as code
UNION ALL
select 'HNL' as currency, 'HNDIR' as code
UNION ALL
select 'HRK' as currency, 'HRVIR' as code
UNION ALL
select 'HTG' as currency, 'HTIIR' as code
UNION ALL
select 'HUF' as currency, 'HUNIR' as code
UNION ALL
select 'IDR' as currency, 'IDNIR' as code
UNION ALL
select 'INR' as currency, 'INDIR' as code
UNION ALL
select 'IEP' as currency, 'IRLIR' as code
UNION ALL
select 'IRR' as currency, 'IRNIR' as code
UNION ALL
select 'IQD' as currency, 'IRQIR' as code
UNION ALL
select 'ISK' as currency, 'ISLIR' as code
UNION ALL
select 'ILS' as currency, 'ISRIR' as code
UNION ALL
select 'ITL' as currency, 'ITAIR' as code
UNION ALL
select 'JMD' as currency, 'JAMIR' as code
UNION ALL
select 'JOD' as currency, 'JORIR' as code
UNION ALL
select 'JPY' as currency, 'JPNIR' as code
UNION ALL
select 'KZT' as currency, 'KAZIR' as code
UNION ALL
select 'KES' as currency, 'KENIR' as code
UNION ALL
select 'KGS' as currency, 'KGZIR' as code
UNION ALL
select 'KHR' as currency, 'KHMIR' as code
UNION ALL
select 'KRW' as currency, 'KORIR' as code
UNION ALL
select 'KWD' as currency, 'KWTIR' as code
UNION ALL
select 'LAK' as currency, 'LAOIR' as code
UNION ALL
select 'LBP' as currency, 'LBNIR' as code
UNION ALL
select 'LRD' as currency, 'LBRIR' as code
UNION ALL
select 'LYD' as currency, 'LBYIR' as code
UNION ALL
select 'LKR' as currency, 'LKAIR' as code
UNION ALL
select 'LSL' as currency, 'LSOIR' as code
UNION ALL
select 'LTL' as currency, 'LTUIR' as code
UNION ALL
select 'LUF' as currency, 'LUXIR' as code
UNION ALL
select 'LVL' as currency, 'LVAIR' as code
UNION ALL
select 'MOP' as currency, 'MACIR' as code
UNION ALL
select 'MAD' as currency, 'MARIR' as code
UNION ALL
select 'MDL' as currency, 'MDAIR' as code
UNION ALL
select 'MVR' as currency, 'MDVIR' as code
UNION ALL
select 'MXN' as currency, 'MEXIR' as code
UNION ALL
select 'MKD' as currency, 'MKDIR' as code
UNION ALL
select 'MRO' as currency, 'MLTIR' as code
UNION ALL
select 'MMK' as currency, 'MMRIR' as code
UNION ALL
select 'MNT' as currency, 'MNGIR' as code
UNION ALL
select 'MZN' as currency, 'MOZIR' as code
UNION ALL
select 'MUR' as currency, 'MUSIR' as code
UNION ALL
select 'MWK' as currency, 'MWIIR' as code
UNION ALL
select 'MYR' as currency, 'MYSIR' as code
UNION ALL
select 'NAD' as currency, 'NAMIR' as code
UNION ALL
select 'NGN' as currency, 'NGAIR' as code
UNION ALL
select 'NOK' as currency, 'NORIR' as code
UNION ALL
select 'NPR' as currency, 'NPLIR' as code
UNION ALL
select 'NZD' as currency, 'NZLIR' as code
UNION ALL
select 'OMR' as currency, 'OMNIR' as code
UNION ALL
select 'PKR' as currency, 'PAKIR' as code
UNION ALL
select 'PAB' as currency, 'PANIR' as code
UNION ALL
select 'PEN' as currency, 'PERIR' as code
UNION ALL
select 'PHP' as currency, 'PHLIR' as code
UNION ALL
select 'PGK' as currency, 'PNGIR' as code
UNION ALL
select 'PLN' as currency, 'POLIR' as code
UNION ALL
select 'PTE' as currency, 'PRTIR' as code
UNION ALL
select 'PYG' as currency, 'PRYIR' as code
UNION ALL
select 'QAR' as currency, 'QATIR' as code
UNION ALL
select 'ROL' as currency, 'ROUIR' as code
UNION ALL
select 'RON' as currency, 'ROUIR' as code
UNION ALL
select 'RUB' as currency, 'RUSIR' as code
UNION ALL
select 'RWF' as currency, 'RWAIR' as code
UNION ALL
select 'SAR' as currency, 'SAUIR' as code
UNION ALL
select 'SGD' as currency, 'SGPIR' as code
UNION ALL
select 'SLL' as currency, 'SLEIR' as code
UNION ALL
select 'SVC' as currency, 'SLVIR' as code
UNION ALL
select 'RSD' as currency, 'SRBIR' as code
UNION ALL
select 'STD' as currency, 'STPIR' as code
UNION ALL
select 'SKK' as currency, 'SVKIR' as code
UNION ALL
select 'SIT' as currency, 'SVNIR' as code
UNION ALL
select 'SEK' as currency, 'SWEIR' as code
UNION ALL
select 'SZL' as currency, 'SWZIR' as code
UNION ALL
select 'THB' as currency, 'THAIR' as code
UNION ALL
select 'TJS' as currency, 'TJKIR' as code
UNION ALL
select 'TTD' as currency, 'TTOIR' as code
UNION ALL
select 'TND' as currency, 'TUNIR' as code
UNION ALL
select 'TRY' as currency, 'TURIR' as code
UNION ALL
select 'TWD' as currency, 'TWNIR' as code
UNION ALL
select 'TZS' as currency, 'TZAIR' as code
UNION ALL
select 'UGX' as currency, 'UGAIR' as code
UNION ALL
select 'UAH' as currency, 'UKRIR' as code
UNION ALL
select 'UYU' as currency, 'URYIR' as code
UNION ALL
select 'USD' as currency, 'USAIR' as code
UNION ALL
select 'UZS' as currency, 'UZBIR' as code
UNION ALL
select 'VEF' as currency, 'VENIR' as code
UNION ALL
select 'VND' as currency, 'VNMIR' as code
UNION ALL
select 'ZAR' as currency, 'ZAFIR' as code
UNION ALL
select 'ZMW' as currency, 'ZMBIR' as code
UNION ALL
select 'ZMK' as currency, 'ZMBIR' as code
UNION ALL
select 'ZWD' as currency, 'ZWEIR' as code
