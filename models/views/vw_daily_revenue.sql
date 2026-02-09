{{
  config(
    materialized='view',
    schema='analytics',
    tags=['views', 'kpi', 'revenue'],
    meta={'owner': 'analytics', 'kpi': 'Revenue Analytics'}
  )
}}

select
  created_date,
  currency,
  debtor_customer_type,
  count(*) as transaction_count,
  count(distinct debtor_customer_id) as unique_debtors,
  count(distinct creditor_customer_id) as unique_creditors,
  sum(gross_amount) as total_amount,
  sum(net_amount) as net_amount,
  sum(total_fees) as total_fees_collected,
  avg(gross_amount) as avg_transaction_size,
  min(gross_amount) as min_transaction_amount,
  max(gross_amount) as max_transaction_amount
from {{ ref('fct_transactions') }}
where status = 'completed'
group by
  created_date,
  currency,
  debtor_customer_type
order by created_date desc, currency