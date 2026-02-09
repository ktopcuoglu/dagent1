{{
  config(
    materialized='incremental',
    schema='marts',
    unique_key='dispute_id',
    on_schema_change='fail',
    tags=['facts', 'disputes'],
    meta={'owner': 'analytics', 'sla': 4}
  )
}}

with disputes as (
  select * from {{ ref('stg_disputes') }}
),

transactions as (
  select * from {{ ref('stg_transactions') }}
),

joined as (
  select
    d.dispute_id,
    {{ dbt_utils.generate_surrogate_key(['d.dispute_id']) }} as dispute_sk,
    d.transaction_id,
    t.debtor_customer_id,
    t.creditor_customer_id,
    d.amount as disputed_amount,
    t.currency,
    d.reason as dispute_reason,
    d.status as dispute_status,
    cast(date(d.created_at) as date) as created_date,
    cast(date(d.updated_at) as date) as updated_date,
    d.created_at,
    d.updated_at,
    date_diff(date(d.updated_at), date(d.created_at), day) as dispute_resolution_days,
    current_timestamp() as dbt_loaded_at
  from disputes d
  left join transactions t on d.transaction_id = t.transaction_id
)

select * from joined

{% if execute %}
  {% if run_started_at is not none %}
    where updated_at > '{{ run_started_at }}'
  {% endif %}
{% endif %}