{{
  config(
    materialized='incremental',
    schema='marts',
    unique_key='transaction_id',
    on_schema_change='fail',
    tags=['facts', 'transactions'],
    meta={'owner': 'analytics', 'sla': 4}
  )
}}

with txn_with_fees as (
  select * from {{ ref('int_transactions_with_fees') }}
),

customers as (
  select * from {{ ref('stg_customers') }}
),

enriched as (
  select
    t.transaction_id,
    {{ dbt_utils.generate_surrogate_key(['t.transaction_id']) }} as transaction_sk,
    t.debtor_customer_id,
    t.creditor_customer_id,
    t.payment_method_id,
    t.gross_amount,
    t.net_amount,
    t.total_fees,
    t.platform_fee,
    t.processing_fee,
    t.interchange_fee,
    t.fee_percentage,
    t.fee_classification,
    t.currency,
    t.status,
    -- Customer context
    c_debtor.customer_type as debtor_customer_type,
    c_debtor.kyc_status as debtor_kyc_status,
    c_debtor.risk_profile as debtor_risk_profile,
    c_creditor.customer_type as creditor_customer_type,
    c_creditor.kyc_status as creditor_kyc_status,
    c_creditor.risk_profile as creditor_risk_profile,
    -- Timestamps
    cast(date(t.created_at) as date) as created_date,
    cast(date(t.updated_at) as date) as updated_date,
    t.created_at,
    t.updated_at,
    current_timestamp() as dbt_loaded_at
  from txn_with_fees t
  left join customers c_debtor on t.debtor_customer_id = c_debtor.customer_id
  left join customers c_creditor on t.creditor_customer_id = c_creditor.customer_id
)

select * from enriched

{% if execute %}
  {% if run_started_at is not none %}
    where updated_at > '{{ run_started_at }}'
  {% endif %}
{% endif %}