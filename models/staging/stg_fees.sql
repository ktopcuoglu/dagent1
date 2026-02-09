{{
  config(
    materialized='view',
    schema='staging',
    tags=['staging', 'fees'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with raw_fees as (
  select
    json_extract_scalar(_airbyte_data, '$.id') as fee_id,
    json_extract_scalar(_airbyte_data, '$.transaction_id') as transaction_id,
    json_extract_scalar(_airbyte_data, '$.fee_type') as fee_type,
    json_extract_scalar(_airbyte_data, '$.amount') as amount,
    json_extract_scalar(_airbyte_data, '$.created_at') as created_at,
    _airbyte_loaded_at
  from {{ source('airbyte_raw', 'airbyte_raw_fees') }}
),

deduped as (
  select
    fee_id,
    transaction_id,
    fee_type,
    amount,
    created_at,
    _airbyte_loaded_at,
    row_number() over (partition by fee_id order by _airbyte_loaded_at desc) as rn
  from raw_fees
)

select
  fee_id,
  transaction_id,
  fee_type,
  cast(amount as numeric) as amount,
  cast(created_at as timestamp) as created_at
from deduped
where rn = 1
  and fee_id is not null