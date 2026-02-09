{{
  config(
    materialized='view',
    schema='staging',
    tags=['staging', 'mandates'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with raw_mandates as (
  select
    json_extract_scalar(_airbyte_data, '$.id') as mandate_id,
    json_extract_scalar(_airbyte_data, '$.customer_id') as customer_id,
    json_extract_scalar(_airbyte_data, '$.payment_method_id') as payment_method_id,
    json_extract_scalar(_airbyte_data, '$.status') as status,
    json_extract_scalar(_airbyte_data, '$.created_at') as created_at,
    json_extract_scalar(_airbyte_data, '$.updated_at') as updated_at,
    _airbyte_loaded_at
  from {{ source('airbyte_raw', 'airbyte_raw_mandates') }}
),

deduped as (
  select
    mandate_id,
    customer_id,
    payment_method_id,
    status,
    created_at,
    updated_at,
    _airbyte_loaded_at,
    row_number() over (partition by mandate_id order by _airbyte_loaded_at desc) as rn
  from raw_mandates
)

select
  mandate_id,
  customer_id,
  payment_method_id,
  status,
  cast(created_at as timestamp) as created_at,
  cast(updated_at as timestamp) as updated_at
from deduped
where rn = 1
  and mandate_id is not null