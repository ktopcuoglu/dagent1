{{
  config(
    materialized='view',
    schema='analytics',
    tags=['views', 'kpi', 'payouts'],
    meta={'owner': 'analytics', 'kpi': 'Payout Metrics'}
  )
}}

with payout_stats as (
  select
    cast(date(created_at) as date) as payout_date,
    status as payout_status,
    count(*) as payout_count,
    sum(amount) as total_payout_amount,
    avg(amount) as avg_payout_amount,
    min(amount) as min_payout_amount,
    max(amount) as max_payout_amount
  from {{ ref('stg_payouts') }}
  group by cast(date(created_at) as date), status
),

customer_context as (
  select
    p.payout_date,
    p.payout_status,
    c.customer_type as recipient_type,
    p.payout_count,
    p.total_payout_amount,
    p.avg_payout_amount
  from payout_stats p
  left join {{ ref('stg_payouts') }} sp on p.payout_date = cast(date(sp.created_at) as date)
  left join {{ ref('dim_customers') }} c on sp.recipient_customer_id = c.customer_id
)

select
  payout_date,
  payout_status,
  recipient_type,
  payout_count,
  total_payout_amount,
  round(avg_payout_amount, 2) as avg_payout_amount,
  sum(case when payout_status = 'executed' then payout_count else 0 end) as executed_payouts,
  sum(case when payout_status = 'pending' then payout_count else 0 end) as pending_payouts,
  sum(case when payout_status = 'scheduled' then payout_count else 0 end) as scheduled_payouts,
  round(
    case
      when sum(payout_count) > 0
        then sum(case when payout_status = 'executed' then payout_count else 0 end) * 100.0 / sum(payout_count)
      else 0
    end,
    2
  ) as payout_success_rate_percent,
  sum(case when payout_status = 'pending' then total_payout_amount else 0 end) as pending_payout_amount
from customer_context
group by payout_date, payout_status, recipient_type
order by payout_date desc, payout_status