{{ config(
    materialized='table'
    , partition_by={
        'field': 'metric_date'
        , 'data_type': 'date'
    }
    , cluster_by=['user_fk', 'query_fk', 'metric_date']
    , meta = {
            'area': 'monitoring'
            , 'system': 'Bigquery Analytics'
            , 'table': 'fact_bigquery_job_statistics'
            , 'category': 'fact'
            , 'business_questions': [
                'What are the metrics by user, query, and date?'
            ]
            , 'joins': [
                'dim_user: fact_query_metrics.user_fk = dim_user.user_sk'
                , 'dim_query: fact_query_metrics.job_fk = dim_query.job_sk'
                , 'dim_calendar: fact_query_metrics.metric_date = dim_calendar.metric_date'
            ]
        }
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
        select date_day
        from {{ ref('dbt_utils_days') }}
    )
    , fact_query_metrics as (
        select
            job_id
            , user_id
            , metric_date
            , start_time
            , end_time
            , referenced_dataset_id
            , referenced_table_id
            , destination_dataset_id
            , destination_table_id
            , timestamp_diff(end_time, start_time, second) as query_time
            , total_processed_bytes/(1048576) as total_processed_mb
            , (total_billed_bytes/(1048576)) as total_billed_mb
            , (total_billed_bytes/(1099511627776)) as query_cost_usd
            , (total_billed_bytes/(1099511627776)*5) as query_cost_brl
            , total_tables_processed
            , total_slot_ms_processed/1000 as total_slot_processed
        from {{ ref('stg_cloudaudit_googleapis_com_data_access') }}
    )
    , fact_job_statistics as (
        select
            {{ numeric_surrogate_key([
                'dim_user.user_sk'
                , 'dim_query.query_sk'
                , 'fact_query_metrics.metric_date'
            ]) }} as metrics_sk
            , dim_user.user_sk as user_fk
            , dim_query.query_sk as query_fk
            , utils_days.date_day
            , fact_query_metrics.start_time
            , fact_query_metrics.end_time
            , fact_query_metrics.referenced_dataset_id
            , fact_query_metrics.referenced_table_id
            , fact_query_metrics.destination_dataset_id
            , fact_query_metrics.destination_table_id
            , fact_query_metrics.query_time
            , fact_query_metrics.total_processed_mb
            , fact_query_metrics.total_billed_mb
            , fact_query_metrics.query_cost_usd
            , fact_query_metrics.query_cost_brl
            , fact_query_metrics.total_tables_processed
            , fact_query_metrics.total_slot_processed
        from fact_query_metrics
        left join dim_user on fact_query_metrics.user_id = dim_user.user_id
        left join dim_query on fact_query_metrics.job_id = dim_query.job_id
        left join utils_days on fact_query_metrics.metric_date = utils_days.date_day
    )
select *
from fact_job_statistics