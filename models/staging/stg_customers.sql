{{
  config(
    materialized='view',
    schema='staging',
    tags=['staging', 'customers'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with raw_customers as (
  select
    json_extract_scalar(_airbyte_data, '$.id') as customer_id,
    json_extract_scalar(_airbyte_data, '$.customer_type') as customer_type,
    json_extract_scalar(_airbyte_data, '$.email') as email,
    json_extract_scalar(_airbyte_data, '$.kyc_status') as kyc_status,
    json_extract_scalar(_airbyte_data, '$.risk_profile') as risk_profile,
    json_extract_scalar(_airbyte_data, '$.address') as address_json,
    json_extract_scalar(_airbyte_data, '$.created_at') as created_at,
    json_extract_scalar(_airbyte_data, '$.updated_at') as updated_at,
    _airbyte_loaded_at
  from {{ source('airbyte_raw', 'airbyte_raw_customers') }}
),

deduped as (
  select
    customer_id,
    customer_type,
    email,
    kyc_status,
    risk_profile,
    address_json,
    created_at,
    updated_at,
    _airbyte_loaded_at,
    row_number() over (partition by customer_id order by _airbyte_loaded_at desc) as rn
  from raw_customers
)

select
  customer_id,
  customer_type,
  email,
  kyc_status,
  risk_profile,
  address_json,
  cast(created_at as timestamp) as created_at,
  cast(updated_at as timestamp) as updated_at
from deduped
where rn = 1
  and customer_id is not null