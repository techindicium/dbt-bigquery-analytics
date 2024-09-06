{{ config(
    cluster_by=['job_id']
) }}

with
    dim_query as (
        select distinct
            job_id
            , query
            , query_dbt_target
            , referenced_dataset_id
            , destination_dataset_id
        from {{ ref('stg_bigquery_analytics_information_schema_jobs') }}
    )
    , dim_query_type as (
        select
            job_id
            , query
            , query_dbt_target
            , referenced_dataset_id
            , destination_dataset_id
            , case
                when query like '%dbt_version%' then 'dbt'
                when query like '%C1%' then 'Power BI'
                when job_id like '%airflow%' then 'Airflow'
                else 'Bigquery'
            end as query_type
        from dim_query
    )
    , dim_query_target_and_reference as (
        select
            {{ dbt_utils.generate_surrogate_key(['job_id']) }} as query_sk
            , job_id
            , query
            , query_type
            , referenced_dataset_id
            , destination_dataset_id
            , case
                when query_type like '%dbt%' and query like '%model%' then 'dbt model'
                when query_type like '%dbt%' and query like '%seed%' then 'dbt seed'
                when query_type like '%dbt%' and query like '%snapshots%' then 'dbt snapshots'
                when query_type like '%dbt%' then 'dbt test'
                else 'Inaplicable'
            end as query_dbt_type
            , coalesce(query_dbt_target, 'Inaplicable') as query_dbt_target
            , case
                {% for dbt_source in var('dbt_sources', '') -%}
                    when query_type like '%dbt%' and query like '%_{{ dbt_source }}_%' then '{{ dbt_source }}'
                {% endfor %}
                else 'Inaplicable'
            end as dbt_source_reference
        from dim_query_type
    )
    , dim_query_objective as (
        select
            query_sk
            , job_id
            , query
            , query_type
            , query_dbt_type
            , query_dbt_target
            , dbt_source_reference
            , case
                when (
                    referenced_dataset_id like '%region-us%'
                    or referenced_dataset_id like '%{{ var("dbt_source_monitoring_dataset", "") }}%'
                    or destination_dataset_id = '{{ var("dbt_prod_monitoring_dataset", "") }}') then 'Monitoring'
                when query_dbt_target = '{{ var("ci_dbt_target", "") }}' then 'CI'
                when query_dbt_target = '{{ var("prod_dbt_target", "") }}' and query_dbt_type = 'dbt model' then 'PROD model'
                when query_dbt_target = '{{ var("prod_dbt_target", "") }}' and query_dbt_type = 'dbt test' then 'PROD test'
                when query_dbt_target = '{{ var("dev_dbt_target", "") }}' and query_dbt_type = 'dbt model' then 'DEV model'
                when query_dbt_target = '{{ var("dev_dbt_target", "") }}' and query_dbt_type = 'dbt test' then 'DEV test'
                when query_type = 'Bigquery' then 'Console Bigquery'
                when query_type = 'Power BI' then 'Power BI'
                when query_type = 'Airflow' then 'Airflow'
                else 'Undefined'
            end as objective
        from dim_query_target_and_reference
    )
select *
from dim_query_objective
