{{
  config(
    materialized='table',
    schema='marts',
    unique_key='customer_id',
    tags=['dimensions', 'customers'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with customers as (
  select
    customer_id,
    customer_type,
    email,
    kyc_status,
    risk_profile,
    created_at,
    updated_at,
    -- Add surrogate key
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk
  from {{ ref('stg_customers') }}
)

select
  customer_sk,
  customer_id,
  customer_type,
  email,
  kyc_status,
  risk_profile,
  cast(date(created_at) as date) as created_date,
  cast(date(updated_at) as date) as updated_date,
  current_timestamp() as dbt_loaded_at
from customers