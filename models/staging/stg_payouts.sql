{{
  config(
    materialized='view',
    schema='staging',
    tags=['staging', 'payouts'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with raw_payouts as (
  select
    json_extract_scalar(_airbyte_data, '$.id') as payout_id,
    json_extract_scalar(_airbyte_data, '$.recipient_customer_id') as recipient_customer_id,
    json_extract_scalar(_airbyte_data, '$.amount') as amount,
    json_extract_scalar(_airbyte_data, '$.currency') as currency,
    json_extract_scalar(_airbyte_data, '$.status') as status,
    json_extract_scalar(_airbyte_data, '$.created_at') as created_at,
    json_extract_scalar(_airbyte_data, '$.updated_at') as updated_at,
    _airbyte_loaded_at
  from {{ source('airbyte_raw', 'airbyte_raw_payouts') }}
),

deduped as (
  select
    payout_id,
    recipient_customer_id,
    amount,
    currency,
    status,
    created_at,
    updated_at,
    _airbyte_loaded_at,
    row_number() over (partition by payout_id order by _airbyte_loaded_at desc) as rn
  from raw_payouts
)

select
  payout_id,
  recipient_customer_id,
  cast(amount as numeric) as amount,
  currency,
  status,
  cast(created_at as timestamp) as created_at,
  cast(updated_at as timestamp) as updated_at
from deduped
where rn = 1
  and payout_id is not null