{{
  config(
    materialized='incremental',
    schema='marts',
    unique_key='refund_id',
    on_schema_change='fail',
    tags=['facts', 'refunds'],
    meta={'owner': 'analytics', 'sla': 4}
  )
}}

with refund_txn as (
  select * from {{ ref('int_refund_transactions') }}
),

enriched as (
  select
    refund_id,
    {{ dbt_utils.generate_surrogate_key(['refund_id']) }} as refund_sk,
    transaction_id,
    debtor_customer_id,
    creditor_customer_id,
    original_transaction_amount,
    refund_amount,
    currency,
    refund_reason,
    refund_reason_category,
    refund_status,
    refund_severity,
    refund_percentage,
    net_revenue_after_refund,
    is_suspicious_refund,
    days_to_refund,
    cast(date(refund_date) as date) as refund_date,
    cast(date(transaction_date) as date) as transaction_date,
    refund_date,
    transaction_date,
    current_timestamp() as dbt_loaded_at
  from refund_txn
)

select * from enriched

{% if execute %}
  {% if run_started_at is not none %}
    where refund_date > '{{ run_started_at }}'
  {% endif %}
{% endif %}