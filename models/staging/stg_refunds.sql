{{
  config(
    materialized='view',
    schema='staging',
    tags=['staging', 'refunds'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with raw_refunds as (
  select
    json_extract_scalar(_airbyte_data, '$.id') as refund_id,
    json_extract_scalar(_airbyte_data, '$.transaction_id') as transaction_id,
    json_extract_scalar(_airbyte_data, '$.amount') as amount,
    json_extract_scalar(_airbyte_data, '$.reason') as reason,
    json_extract_scalar(_airbyte_data, '$.status') as status,
    json_extract_scalar(_airbyte_data, '$.created_at') as created_at,
    json_extract_scalar(_airbyte_data, '$.updated_at') as updated_at,
    _airbyte_loaded_at
  from {{ source('airbyte_raw', 'airbyte_raw_refunds') }}
),

deduped as (
  select
    refund_id,
    transaction_id,
    amount,
    reason,
    status,
    created_at,
    updated_at,
    _airbyte_loaded_at,
    row_number() over (partition by refund_id order by _airbyte_loaded_at desc) as rn
  from raw_refunds
)

select
  refund_id,
  transaction_id,
  cast(amount as numeric) as amount,
  reason,
  status,
  cast(created_at as timestamp) as created_at,
  cast(updated_at as timestamp) as updated_at
from deduped
where rn = 1
  and refund_id is not null