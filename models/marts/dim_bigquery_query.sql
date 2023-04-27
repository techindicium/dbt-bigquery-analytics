{{ config(
    materialized='table'
    , partition_by={
        'field': 'query_sk'
        , 'data_type': 'int64'
        , "range": {
            "start": -9223372036854775807
            , "end": 9223372036854775807
            , "interval": 18446744073709500
        }
    }
    , cluster_by=['job_id']
    , meta = {
            'area': 'monitoring'
            , 'system': 'Bigquery Analytics'
            , 'table': 'dim__bigquery_query'
            , 'category': 'dimension'
        }
) }}

with
    dim_query as (
        select distinct
            job_id
            , query
        from {{ ref('stg_cloudaudit_googleapis_com_data_access') }}
    )
    , dim_query_type as (
        select
            job_id
            , query
            , case
                when query like '%dbt_version%' then 'dbt'
                when query like '%C1%' then 'Power BI'
                when query like '%HEVO%' then 'Hevo'
                else 'Bigquery'
            end as query_type
        from dim_query
    )
    , dim_query_sk as (
        select
            {{ numeric_surrogate_key(['job_id']) }} as query_sk
            , job_id
            , query
            , query_type
            , case
                when query_type like '%dbt%' and query like '%model%' then 'dbt model'
                when query_type like '%dbt%' and query like '%seed%' then 'dbt seed'
                when query_type like '%dbt%' and query like '%snapshots%' then 'dbt snapshots'
                when query_type like '%dbt%' then 'dbt test'
                else 'Inaplicable'
            end as query_dbt_type
        from dim_query_type
    )
select *
from dim_query_sk