WITH
  all_reporting_dates AS (
  SELECT
    fsym_id,
    report_date
  FROM
    `factset_estimates.fe_basic_act_af`
  UNION ALL
  SELECT
    fsym_id,
    report_date
  FROM
    `factset_estimates.fe_basic_act_qf`
  UNION ALL
  SELECT
    fsym_id,
    report_date
  FROM
    `factset_estimates.fe_basic_act_saf` ),
  distinct_report_dates AS (
  SELECT
    DISTINCT fsym_id,
    report_date
  FROM
    all_reporting_dates),
dense_dates as (
SELECT
  fsym_id,
  date,
  last_value(last_report_date IGNORE NULLS) over (partition by fsym_id order by date) as latest_report_date,
  last_value(next_report_date IGNORE NULLS) over (partition by fsym_id order by date) as next_report_date
from `sixty_security_ts.security_dates` , unnest(date) date
LEFT JOIN (
  SELECT
    fsym_id,
    report_date as date,
    report_date as last_report_date,
    LEAD(report_date, 1) OVER (PARTITION BY fsym_id ORDER BY report_date) next_report_date
    from distinct_report_dates) t
  using (date, fsym_id)
)
select
  fsym_id,
  array_agg((
  select as struct
  date,
  latest_report_date=date as is_earnings_date,
  date_diff(next_report_date, date, day) as days_to_next_earnings
  )) ts
from dense_dates
group by fsym_id 
