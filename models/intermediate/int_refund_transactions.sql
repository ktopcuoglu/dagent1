{{
  config(
    materialized='ephemeral',
    tags=['intermediate', 'refunds'],
    meta={'owner': 'analytics'}
  )
}}

with refunds as (
  select * from {{ ref('stg_refunds') }}
),

transactions as (
  select * from {{ ref('stg_transactions') }}
),

joined as (
  select
    r.refund_id,
    r.transaction_id,
    t.debtor_customer_id,
    t.creditor_customer_id,
    t.amount as original_transaction_amount,
    r.amount as refund_amount,
    t.currency,
    r.reason as refund_reason,
    r.status as refund_status,
    r.created_at as refund_date,
    t.created_at as transaction_date,
    date_diff(date(r.created_at), date(t.created_at), day) as days_to_refund,
    t.amount - r.amount as net_revenue_after_refund
  from refunds r
  left join transactions t on r.transaction_id = t.transaction_id
)

select
  refund_id,
  transaction_id,
  debtor_customer_id,
  creditor_customer_id,
  original_transaction_amount,
  refund_amount,
  currency,
  refund_reason,
  refund_status,
  refund_date,
  transaction_date,
  days_to_refund,
  net_revenue_after_refund,
  -- Calculate refund percentage
  case
    when original_transaction_amount > 0
      then round(refund_amount / original_transaction_amount * 100, 2)
    else 0
  end as refund_percentage,
  -- Classify refund severity
  case
    when refund_amount > 5000 then 'critical'
    when refund_amount > 1000 then 'high'
    when refund_amount > 100 then 'medium'
    else 'low'
  end as refund_severity,
  -- Categorize refund reason
  case
    when refund_reason ilike '%customer%' or refund_reason ilike '%request%' then 'customer_initiated'
    when refund_reason ilike '%fraud%' then 'fraud'
    when refund_reason ilike '%error%' or refund_reason ilike '%system%' then 'system_error'
    else 'other'
  end as refund_reason_category,
  -- Flag suspicious refunds
  case
    when days_to_refund < 1 then true  -- Immediate refund
    when refund_amount > original_transaction_amount * 1.5 then true  -- Refund exceeds original
    when refund_reason ilike '%fraud%' then true
    else false
  end as is_suspicious_refund
from joined