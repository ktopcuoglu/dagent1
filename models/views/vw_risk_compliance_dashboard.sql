{{
  config(
    materialized='view',
    schema='analytics',
    tags=['views', 'kpi', 'risk_compliance'],
    meta={'owner': 'analytics', 'kpi': 'Risk & Compliance Dashboard'}
  )
}}

with customer_kyc_stats as (
  select
    kyc_status,
    risk_profile,
    customer_type,
    count(*) as customer_count,
    count(distinct customer_id) as unique_customers
  from {{ ref('dim_customers') }}
  group by kyc_status, risk_profile, customer_type
),

transaction_risk_stats as (
  select
    created_date,
    debtor_kyc_status,
    debtor_risk_profile,
    debtor_customer_type,
    count(*) as transaction_count,
    sum(gross_amount) as transaction_volume,
    sum(case when debtor_risk_profile = 'high' then 1 else 0 end) as high_risk_transaction_count,
    sum(case when debtor_kyc_status = 'pending' then 1 else 0 end) as pending_kyc_transaction_count,
    sum(case when debtor_kyc_status = 'verified' then 1 else 0 end) as verified_kyc_transaction_count
  from {{ ref('fct_transactions') }}
  where status = 'completed'
  group by created_date, debtor_kyc_status, debtor_risk_profile, debtor_customer_type
)

select
  coalesce(c.kyc_status, t.debtor_kyc_status) as kyc_status,
  coalesce(c.risk_profile, t.debtor_risk_profile) as risk_profile,
  coalesce(c.customer_type, t.debtor_customer_type) as customer_type,
  current_date() as report_date,
  coalesce(c.unique_customers, 0) as total_customers,
  coalesce(t.transaction_count, 0) as total_transactions,
  coalesce(t.transaction_volume, 0) as total_transaction_volume,
  coalesce(t.high_risk_transaction_count, 0) as high_risk_transaction_count,
  coalesce(t.pending_kyc_transaction_count, 0) as pending_kyc_transaction_count,
  coalesce(t.verified_kyc_transaction_count, 0) as verified_kyc_transaction_count,
  round(
    case
      when coalesce(t.transaction_count, 0) > 0
        then coalesce(t.high_risk_transaction_count, 0) * 100.0 / t.transaction_count
      else 0
    end,
    2
  ) as high_risk_transaction_rate_percent,
  round(
    case
      when coalesce(c.unique_customers, 0) > 0
        then sum(case when c.kyc_status = 'verified' then 1 else 0 end) * 100.0 / c.unique_customers
      else 0
    end,
    2
  ) as kyc_verification_rate_percent
from customer_kyc_stats c
full outer join transaction_risk_stats t
  on c.kyc_status = t.debtor_kyc_status
  and c.risk_profile = t.debtor_risk_profile
  and c.customer_type = t.debtor_customer_type
group by
  kyc_status,
  risk_profile,
  customer_type,
  total_customers,
  total_transactions,
  total_transaction_volume,
  high_risk_transaction_count,
  pending_kyc_transaction_count,
  verified_kyc_transaction_count
order by high_risk_transaction_rate_percent desc