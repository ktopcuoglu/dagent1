{{
  config(
    materialized='view',
    schema='staging',
    tags=['staging', 'transaction_legs'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with raw_transaction_legs as (
  select
    json_extract_scalar(_airbyte_data, '$.id') as transaction_leg_id,
    json_extract_scalar(_airbyte_data, '$.transaction_id') as transaction_id,
    json_extract_scalar(_airbyte_data, '$.leg_type') as leg_type,
    json_extract_scalar(_airbyte_data, '$.amount') as amount,
    json_extract_scalar(_airbyte_data, '$.created_at') as created_at,
    _airbyte_loaded_at
  from {{ source('airbyte_raw', 'airbyte_raw_transaction_legs') }}
),

deduped as (
  select
    transaction_leg_id,
    transaction_id,
    leg_type,
    amount,
    created_at,
    _airbyte_loaded_at,
    row_number() over (partition by transaction_leg_id order by _airbyte_loaded_at desc) as rn
  from raw_transaction_legs
)

select
  transaction_leg_id,
  transaction_id,
  leg_type,
  cast(amount as numeric) as amount,
  cast(created_at as timestamp) as created_at
from deduped
where rn = 1
  and transaction_leg_id is not null