{{ config(
    materialized='incremental'
    , incremental_strategy='merge'
    , unique_key = 'job_id'
    , partition_by={
        'field': 'metric_date'
        , 'data_type': 'date'
    }
) }}

with
    info_schema as (
        select
            job_id
            , user_email as user_id
            , cast(creation_time as date) as metric_date
            , job_type
            , query
            , json_extract_scalar(regexp_extract(query, r'/\*(.*?)\*/'), '$.target_name') as query_dbt_target
            , cast(start_time as timestamp) as start_timestamp
            , cast(end_time as timestamp) as end_timestamp
            , referenced_tables[SAFE_OFFSET(0)].dataset_id as referenced_dataset_id
            , referenced_tables[SAFE_OFFSET(0)].table_id as referenced_table_id
            , destination_table.dataset_id as destination_dataset_id
            , destination_table.table_id as destination_table_id
            , total_slot_ms as total_slot_ms_processed
            , total_bytes_processed
            , total_bytes_billed
        from {{ source('bigquery_info_schema', 'information_schema_jobs') }}
        {% if is_incremental() %}
        /* this filter will only be applied on an incremental run */
        where cast(creation_time as date) > (select max(cast(creation_time as date)) from {{ this }})
        {% endif %}
    )

select *
from info_schema
