{{
  config(
    materialized='table',
    schema='marts',
    unique_key='date_id',
    tags=['dimensions', 'dates'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with date_spine as (
  select
    cast(date_series as date) as full_date
  from unnest(
    generate_date_array(
      cast('{{ var("start_date") }}' as date),
      cast('{{ var("end_date") }}' as date),
      interval 1 day
    )
  ) as date_series
)

select
  {{ dbt_utils.generate_surrogate_key(['full_date']) }} as date_id,
  full_date,
  extract(year from full_date) as year,
  extract(quarter from full_date) as quarter,
  extract(month from full_date) as month,
  format_date('%B', full_date) as month_name,
  extract(dayofweek from full_date) as day_of_week,
  format_date('%A', full_date) as day_of_week_name,
  case when extract(dayofweek from full_date) in (1, 7) then true else false end as is_weekend,
  -- Simple holiday flag (can be enhanced with external holiday table)
  case
    when (extract(month from full_date) = 1 and extract(day from full_date) = 1) then true  -- New Year
    when (extract(month from full_date) = 12 and extract(day from full_date) = 25) then true  -- Christmas
    else false
  end as is_holiday
from date_spine