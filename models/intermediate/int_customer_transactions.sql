{{
  config(
    materialized='ephemeral',
    tags=['intermediate', 'customers'],
    meta={'owner': 'analytics'}
  )
}}

with txn_with_fees as (
  select * from {{ ref('int_transactions_with_fees') }}
),

customers as (
  select * from {{ ref('stg_customers') }}
),

-- Unpivot transactions to customer perspective (1 txn → 2 rows: debtor + creditor)
customer_txn_unpivoted as (
  -- Debtor perspective (money going out)
  select
    transaction_id,
    debtor_customer_id as customer_id,
    'debtor' as customer_role,
    -1 * gross_amount as signed_amount,
    currency,
    status,
    created_at
  from txn_with_fees
  
  union all
  
  -- Creditor perspective (money coming in)
  select
    transaction_id,
    creditor_customer_id as customer_id,
    'creditor' as customer_role,
    gross_amount as signed_amount,
    currency,
    status,
    created_at
  from txn_with_fees
),

enriched as (
  select
    cu.txn.transaction_id,
    cu.txn.customer_id,
    cu.txn.customer_role,
    cu.txn.signed_amount,
    cu.txn.currency,
    cu.txn.status,
    c.customer_type,
    c.kyc_status,
    c.risk_profile,
    cu.txn.created_at,
    -- Determine lifecycle stage (new vs existing)
    case
      when c.created_at >= date_sub(cu.txn.created_at, interval 30 day) then 'new'
      else 'existing'
    end as customer_lifecycle_stage,
    -- Assess transaction risk level
    case
      when c.risk_profile = 'high' or c.kyc_status = 'pending' then 'critical'
      when c.risk_profile = 'medium' or c.kyc_status = 'under_review' then 'elevated'
      else 'standard'
    end as transaction_risk_level,
    -- Flag for compliance review
    case
      when c.risk_profile = 'high' or c.kyc_status = 'pending' or abs(cu.txn.signed_amount) > 10000 then true
      else false
    end as requires_compliance_review
  from customer_txn_unpivoted cu.txn
  left join customers c on cu.txn.customer_id = c.customer_id
)

select * from enriched