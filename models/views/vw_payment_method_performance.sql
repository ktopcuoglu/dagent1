{{
  config(
    materialized='view',
    schema='analytics',
    tags=['views', 'kpi', 'payment_methods'],
    meta={'owner': 'analytics', 'kpi': 'Payment Method Performance'}
  )
}}

with payment_method_stats as (
  select
    pm.method_type,
    t.status,
    count(*) as transaction_count,
    sum(t.gross_amount) as total_volume,
    avg(t.gross_amount) as avg_transaction_amount,
    sum(case when t.status = 'completed' then 1 else 0 end) as successful_transactions,
    sum(case when t.status != 'completed' then 1 else 0 end) as failed_transactions
  from {{ ref('fct_transactions') }} t
  left join {{ ref('dim_payment_methods') }} pm on t.payment_method_id = pm.payment_method_id
  group by pm.method_type, t.status
)

select
  method_type,
  sum(transaction_count) as total_transactions,
  sum(total_volume) as total_volume,
  round(avg(avg_transaction_amount), 2) as avg_transaction_amount,
  round(
    sum(case when status = 'completed' then transaction_count else 0 end) * 100.0 /
    sum(transaction_count),
    2
  ) as success_rate_percent,
  round(
    sum(case when status != 'completed' then transaction_count else 0 end) * 100.0 /
    sum(transaction_count),
    2
  ) as failure_rate_percent,
  sum(successful_transactions) as successful_transactions,
  sum(failed_transactions) as failed_transactions
from payment_method_stats
group by method_type
order by total_volume desc