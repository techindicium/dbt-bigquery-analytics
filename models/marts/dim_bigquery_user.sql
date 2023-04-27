{{ config(
    materialized='table'
    , partition_by={
        'field': 'user_sk'
        , 'data_type': 'int64'
        , "range": {
            "start": -9223372036854775807
            , "end": 9223372036854775807
            , "interval": 18446744073709500
        }
    }
    , cluster_by=['user_id']
) }}

with
    dim_user as (
        select distinct user_id
        from {{ ref('stg_cloudaudit_googleapis_com_data_access') }}
    )
    , dim_user_sk as (
        select
            {{ numeric_surrogate_key(['user_id']) }} as user_sk
            , *
        from dim_user
    )
select *
from dim_user_sk