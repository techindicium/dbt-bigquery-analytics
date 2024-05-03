{{ config(
    cluster_by=['user_id']
) }}

with
    dim_user as (
        select distinct user_id
        from {{ ref('stg_bigquery_analytics_information_schema_jobs') }}
    )
    , dim_user_sk as (
        select
            {{ dbt_utils.generate_surrogate_key(['user_id']) }} as user_sk
            , *
        from dim_user
    )
select *
from dim_user_sk