{{
  config(
    materialized='ephemeral',
    tags=['intermediate', 'transactions'],
    meta={'owner': 'analytics'}
  )
}}

with transactions as (
  select * from {{ ref('stg_transactions') }}
),

fees_agg as (
  select
    transaction_id,
    sum(case when fee_type = 'platform_fee' then amount else 0 end) as platform_fee,
    sum(case when fee_type = 'processing_fee' then amount else 0 end) as processing_fee,
    sum(case when fee_type = 'interchange_fee' then amount else 0 end) as interchange_fee,
    sum(amount) as total_fees
  from {{ ref('stg_fees') }}
  group by transaction_id
)

select
  t.transaction_id,
  t.debtor_customer_id,
  t.creditor_customer_id,
  t.payment_method_id,
  t.amount as gross_amount,
  t.currency,
  t.status,
  coalesce(f.platform_fee, 0) as platform_fee,
  coalesce(f.processing_fee, 0) as processing_fee,
  coalesce(f.interchange_fee, 0) as interchange_fee,
  coalesce(f.total_fees, 0) as total_fees,
  t.amount - coalesce(f.total_fees, 0) as net_amount,
  case
    when t.amount > 0 then round(coalesce(f.total_fees, 0) / t.amount * 100, 2)
    else 0
  end as fee_percentage,
  case
    when coalesce(f.total_fees, 0) = 0 then 'no_fees'
    when round(coalesce(f.total_fees, 0) / t.amount * 100, 2) < 1 then 'low'
    when round(coalesce(f.total_fees, 0) / t.amount * 100, 2) < 3 then 'medium'
    else 'high'
  end as fee_classification,
  t.created_at,
  t.updated_at
from transactions t
left join fees_agg f on t.transaction_id = f.transaction_id