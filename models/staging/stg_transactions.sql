{{
  config(
    materialized='view',
    schema='staging',
    tags=['staging', 'transactions'],
    meta={'owner': 'analytics', 'sla': 24}
  )
}}

with raw_transactions as (
  select
    json_extract_scalar(_airbyte_data, '$.id') as transaction_id,
    json_extract_scalar(_airbyte_data, '$.debtor_customer_id') as debtor_customer_id,
    json_extract_scalar(_airbyte_data, '$.creditor_customer_id') as creditor_customer_id,
    json_extract_scalar(_airbyte_data, '$.payment_method_id') as payment_method_id,
    json_extract_scalar(_airbyte_data, '$.amount') as amount,
    json_extract_scalar(_airbyte_data, '$.currency') as currency,
    json_extract_scalar(_airbyte_data, '$.status') as status,
    json_extract_scalar(_airbyte_data, '$.created_at') as created_at,
    json_extract_scalar(_airbyte_data, '$.updated_at') as updated_at,
    _airbyte_loaded_at
  from {{ source('airbyte_raw', 'airbyte_raw_transactions') }}
),

deduped as (
  select
    transaction_id,
    debtor_customer_id,
    creditor_customer_id,
    payment_method_id,
    amount,
    currency,
    status,
    created_at,
    updated_at,
    _airbyte_loaded_at,
    row_number() over (partition by transaction_id order by _airbyte_loaded_at desc) as rn
  from raw_transactions
)

select
  transaction_id,
  debtor_customer_id,
  creditor_customer_id,
  payment_method_id,
  cast(amount as numeric) as amount,
  currency,
  status,
  cast(created_at as timestamp) as created_at,
  cast(updated_at as timestamp) as updated_at
from deduped
where rn = 1
  and transaction_id is not null