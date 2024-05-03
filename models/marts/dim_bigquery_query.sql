{{ config(
    cluster_by=['job_id']
) }}

with
    dim_query as (
        select distinct
            job_id
            , query
        from {{ ref('stg_bigquery_analytics_information_schema_jobs') }}
    )
    , dim_query_type as (
        select
            job_id
            , query
            , case
                when query like '%dbt_version%' then 'dbt'
                when query like '%C1%' then 'Power BI'
                else 'Bigquery'
            end as query_type
        from dim_query
    )
    , dim_query_sk as (
        select
            {{ dbt_utils.generate_surrogate_key(['job_id']) }} as query_sk
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