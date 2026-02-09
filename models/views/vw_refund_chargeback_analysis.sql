{{
  config(
    materialized='view',
    schema='analytics',
    tags=['views', 'kpi', 'refunds'],
    meta={'owner': 'analytics', 'kpi': 'Refund & Chargeback Analysis'}
  )
}}

with refund_data as (
  select
    refund_date,
    refund_reason_category,
    refund_severity,
    debtor_customer_id,
    refund_amount,
    original_transaction_amount,
    is_suspicious_refund,
    days_to_refund
  from {{ ref('fct_refunds') }}
),

dispute_data as (
  select
    created_date as dispute_date,
    dispute_reason,
    'dispute' as dispute_type,
    debtor_customer_id,
    disputed_amount,
    dispute_resolution_days
  from {{ ref('fct_disputes') }}
),

transaction_summary as (
  select
    created_date,
    count(*) as total_transactions,
    sum(gross_amount) as total_transaction_amount
  from {{ ref('fct_transactions') }}
  where status = 'completed'
  group by created_date
),

refund_summary as (
  select
    refund_date as date,
    refund_reason_category,
    count(*) as refund_count,
    sum(refund_amount) as total_refund_amount,
    avg(refund_amount) as avg_refund_amount,
    sum(case when is_suspicious_refund then 1 else 0 end) as suspicious_refund_count,
    avg(days_to_refund) as avg_days_to_refund
  from refund_data
  group by refund_date, refund_reason_category
),

dispute_summary as (
  select
    dispute_date as date,
    dispute_reason,
    count(*) as dispute_count,
    sum(disputed_amount) as total_disputed_amount,
    avg(dispute_resolution_days) as avg_resolution_days
  from dispute_data
  group by dispute_date, dispute_reason
)

select
  coalesce(r.date, d.date, t.created_date) as date,
  coalesce(r.refund_reason_category, 'no_refunds') as refund_reason,
  coalesce(d.dispute_reason, 'no_disputes') as dispute_reason,
  coalesce(r.refund_count, 0) as refund_count,
  coalesce(d.dispute_count, 0) as dispute_count,
  coalesce(t.total_transactions, 0) as total_transactions,
  coalesce(r.total_refund_amount, 0) as total_refund_amount,
  coalesce(d.total_disputed_amount, 0) as total_disputed_amount,
  round(
    case
      when coalesce(t.total_transactions, 0) > 0
        then coalesce(r.refund_count, 0) * 100.0 / t.total_transactions
      else 0
    end,
    2
  ) as refund_rate_percent,
  round(
    case
      when coalesce(t.total_transactions, 0) > 0
        then coalesce(d.dispute_count, 0) * 100.0 / t.total_transactions
      else 0
    end,
    2
  ) as dispute_rate_percent,
  coalesce(r.avg_refund_amount, 0) as avg_refund_amount,
  coalesce(d.avg_resolution_days, 0) as avg_dispute_resolution_days,
  coalesce(r.suspicious_refund_count, 0) as suspicious_refund_count
from refund_summary r
full outer join dispute_summary d on r.date = d.date and r.refund_reason_category = d.dispute_reason
full outer join transaction_summary t on coalesce(r.date, d.date) = t.created_date
order by date desc