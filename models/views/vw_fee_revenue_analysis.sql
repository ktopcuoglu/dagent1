{{
  config(
    materialized='view',
    schema='analytics',
    tags=['views', 'kpi', 'fees'],
    meta={'owner': 'analytics', 'kpi': 'Fee Revenue Analysis'}
  )
}}

with fee_data as (
  select
    created_date,
    currency,
    count(*) as transaction_count,
    sum(platform_fee) as platform_fees,
    sum(processing_fee) as processing_fees,
    sum(interchange_fee) as interchange_fees,
    sum(total_fees) as total_fees,
    sum(gross_amount) as total_transaction_amount,
    avg(total_fees) as avg_fee_per_transaction,
    avg(fee_percentage) as avg_fee_percentage
  from {{ ref('fct_transactions') }}
  where status = 'completed'
  group by created_date, currency
)

select
  created_date,
  currency,
  transaction_count,
  total_transaction_amount,
  total_fees,
  platform_fees,
  processing_fees,
  interchange_fees,
  round(avg_fee_per_transaction, 2) as avg_fee_per_transaction,
  round(avg_fee_percentage, 2) as avg_fee_percentage,
  round(
    case
      when total_transaction_amount > 0
        then total_fees * 100.0 / total_transaction_amount
      else 0
    end,
    2
  ) as fee_margin_percent,
  round(
    case
      when total_fees > 0
        then platform_fees * 100.0 / total_fees
      else 0
    end,
    2
  ) as platform_fee_percent_of_total,
  round(
    case
      when total_fees > 0
        then processing_fees * 100.0 / total_fees
      else 0
    end,
    2
  ) as processing_fee_percent_of_total,
  round(
    case
      when total_fees > 0
        then interchange_fees * 100.0 / total_fees
      else 0
    end,
    2
  ) as interchange_fee_percent_of_total
from fee_data
order by created_date desc, currency