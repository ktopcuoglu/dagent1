{{
  config(
    materialized='table',
    schema='marts',
    unique_key='payment_method_id',
    tags=['dimensions', 'payment_methods'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with payment_methods as (
  select
    payment_method_id,
    customer_id,
    method_type,
    is_default,
    created_at,
    -- Add surrogate key
    {{ dbt_utils.generate_surrogate_key(['payment_method_id']) }} as payment_method_sk
  from {{ ref('stg_payment_methods') }}
)

select
  payment_method_sk,
  payment_method_id,
  customer_id,
  method_type,
  is_default,
  cast(date(created_at) as date) as created_date,
  current_timestamp() as dbt_loaded_at
from payment_methods