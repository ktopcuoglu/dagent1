{{
  config(
    materialized='view',
    schema='analytics',
    tags=['views', 'kpi', 'customers'],
    meta={'owner': 'analytics', 'kpi': 'Customer Analytics'}
  )
}}

with customer_stats as (
  select
    customer_id,
    customer_type,
    kyc_status,
    risk_profile,
    created_date,
    -- Active customers in last 30 days
    case
      when max(created_date) >= current_date() - 30 then 1
      else 0
    end as is_active_30d
  from {{ ref('dim_customers') }}
  group by customer_id, customer_type, kyc_status, risk_profile, created_date
),

txn_stats as (
  select
    debtor_customer_id as customer_id,
    count(*) as debtor_transaction_count,
    sum(net_amount) as debtor_total_outflows
  from {{ ref('fct_transactions') }}
  where status = 'completed'
  group by debtor_customer_id

  union all

  select
    creditor_customer_id as customer_id,
    count(*) as creditor_transaction_count,
    sum(net_amount) as creditor_total_inflows
  from {{ ref('fct_transactions') }}
  where status = 'completed'
  group by creditor_customer_id
),

txn_combined as (
  select
    customer_id,
    sum(debtor_transaction_count + creditor_transaction_count) as total_transactions,
    sum(debtor_total_outflows) as total_outflows,
    sum(creditor_total_inflows) as total_inflows
  from txn_stats
  group by customer_id
)

select
  cs.customer_id,
  cs.customer_type,
  cs.kyc_status,
  cs.risk_profile,
  cs.created_date,
  cs.is_active_30d,
  coalesce(tc.total_transactions, 0) as total_transactions,
  coalesce(tc.total_inflows, 0) as customer_lifetime_inflows,
  coalesce(tc.total_outflows, 0) as customer_lifetime_outflows,
  coalesce(tc.total_inflows, 0) - coalesce(tc.total_outflows, 0) as customer_net_position,
  case
    when coalesce(tc.total_transactions, 0) > 0
      then round(coalesce(tc.total_inflows, 0) / coalesce(tc.total_transactions, 1), 2)
    else 0
  end as avg_inflow_per_transaction,
  case
    when coalesce(tc.total_transactions, 0) > 0
      then round(coalesce(tc.total_outflows, 0) / coalesce(tc.total_transactions, 1), 2)
    else 0
  end as avg_outflow_per_transaction
from customer_stats cs
left join txn_combined tc on cs.customer_id = tc.customer_id
order by customer_lifetime_inflows desc