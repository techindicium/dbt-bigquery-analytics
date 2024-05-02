with
    info_schema as (
        select
            job_id
            , user_email as user_id
            , cast(creation_time as date) as metric_date
            , job_type
            , query
            , cast(start_time as timestamp) as start_timestamp
            , cast(end_time as timestamp) as end_timestamp
            , referenced_tables[SAFE_OFFSET(0)].dataset_id as referenced_dataset_id
            , referenced_tables[SAFE_OFFSET(0)].table_id as referenced_table_id
            , destination_table.dataset_id as destination_dataset_id
            , destination_table.table_id as destination_table_id
            , total_slot_ms as total_slot_ms_processed
            , total_bytes_processed
            , total_bytes_billed
        from {{ source('bigquery_info_schema', 'JOBS') }}
    )
select *
from info_schema