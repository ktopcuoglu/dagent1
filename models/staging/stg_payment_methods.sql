{{
  config(
    materialized='view',
    schema='staging',
    tags=['staging', 'payment_methods'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with raw_payment_methods as (
  select
    json_extract_scalar(_airbyte_data, '$.id') as payment_method_id,
    json_extract_scalar(_airbyte_data, '$.customer_id') as customer_id,
    json_extract_scalar(_airbyte_data, '$.method_type') as method_type,
    json_extract_scalar(_airbyte_data, '$.is_default') as is_default,
    json_extract_scalar(_airbyte_data, '$.details') as details_json,
    json_extract_scalar(_airbyte_data, '$.created_at') as created_at,
    _airbyte_loaded_at
  from {{ source('airbyte_raw', 'airbyte_raw_payment_methods') }}
),

deduped as (
  select
    payment_method_id,
    customer_id,
    method_type,
    is_default,
    details_json,
    created_at,
    _airbyte_loaded_at,
    row_number() over (partition by payment_method_id order by _airbyte_loaded_at desc) as rn
  from raw_payment_methods
)

select
  payment_method_id,
  customer_id,
  method_type,
  case when is_default = 'true' then true else false end as is_default,
  details_json,
  cast(created_at as timestamp) as created_at
from deduped
where rn = 1
  and payment_method_id is not null