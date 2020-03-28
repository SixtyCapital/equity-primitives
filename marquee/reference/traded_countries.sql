SELECT
  *
FROM
  UNNEST(['US', 'CA', 'JP', 'GB', 'CH', 'DK', 'DE', 'ES', 'FR', 'IT', 'AU', 'SE', 'NL', 'BE', 'NO', 'FI', 'AT', 'HK']) AS country_iso
