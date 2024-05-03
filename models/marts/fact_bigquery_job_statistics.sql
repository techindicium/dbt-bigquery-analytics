{{ config(
    partition_by={
        'field': 'date_day'
        , 'data_type': 'date'
    }
    , cluster_by=['user_fk', 'query_fk', 'date_day']
) }}

with
    dim_user as (
        select
            user_sk
            , user_id
        from {{ ref('dim_bigquery_user') }}
    )
    , dim_query as (
        select
            query_sk
            , job_id
        from {{ ref('dim_bigquery_query') }}
    )
    , utils_days as (
        select cast(date_day as date) as date_day
        from {{ ref('dbt_utils_days') }}
    )
    , fact_query_metrics as (
        select
            job_id
            , user_id
            , metric_date
            , start_timestamp
            , end_timestamp
            , referenced_dataset_id
            , referenced_table_id
            , destination_dataset_id
            , destination_table_id
            , timestamp_diff(end_timestamp, start_timestamp, second) as query_time
            , total_bytes_processed/(1048576) as total_processed_mb
            , (total_bytes_billed/(1048576)) as total_billed_mb
            , (total_bytes_billed/(1099511627776)) as query_cost_usd
            , (total_bytes_billed/(1099511627776)*5) as query_cost_brl
            , total_slot_ms_processed/1000 as total_slot_processed
        from {{ ref('stg_bigquery_analytics_information_schema_jobs') }}
    )
    , fact_job_statistics as (
        select
            {{ dbt_utils.generate_surrogate_key([
                'dim_user.user_sk'
                , 'dim_query.query_sk'
                , 'fact_query_metrics.metric_date'
            ]) }} as metrics_sk
            , dim_user.user_sk as user_fk
            , dim_query.query_sk as query_fk
            , utils_days.date_day
            , fact_query_metrics.start_timestamp
            , fact_query_metrics.end_timestamp
            , fact_query_metrics.referenced_dataset_id
            , fact_query_metrics.referenced_table_id
            , fact_query_metrics.destination_dataset_id
            , fact_query_metrics.destination_table_id
            , fact_query_metrics.query_time
            , fact_query_metrics.total_processed_mb
            , fact_query_metrics.total_billed_mb
            , fact_query_metrics.query_cost_usd
            , fact_query_metrics.query_cost_brl
            , fact_query_metrics.total_slot_processed
        from fact_query_metrics
        left join dim_user on fact_query_metrics.user_id = dim_user.user_id
        left join dim_query on fact_query_metrics.job_id = dim_query.job_id
        left join utils_days on fact_query_metrics.metric_date = utils_days.date_day
    )
select *
from fact_job_statistics