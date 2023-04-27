with
    renamed as (
        select
            protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobName.jobId as job_id
            , protopayload_auditlog.authenticationInfo.principalEmail as user_id
            , cast(protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.createTime as date) as metric_date
            , resource.type as resource_type
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobConfiguration.query.query as query
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.startTime as start_time
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.endTime as end_time
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.referencedTables[safe_offset(0)].datasetId as referenced_dataset_id
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.referencedTables[safe_offset(0)].TableId as referenced_table_id
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobConfiguration.query.destinationTable.datasetId as destination_dataset_id
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobConfiguration.query.destinationTable.tableId as destination_table_id
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.totalTablesProcessed as total_tables_processed
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.totalSlotMs as total_slot_ms_processed
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.totalProcessedBytes as total_processed_bytes
            , protopayload_auditlog.servicedata_v1_bigquery.jobGetQueryResultsResponse.job.jobStatistics.totalBilledBytes as total_billed_bytes
        from {{ source('bigquery_logging_sink', 'cloudaudit_googleapis_com_data_access') }}
    )
    , deduplicated_last_update as (
        select
            *
            , row_number() over(partition by job_id order by metric_date desc) as last_update
        from renamed
    )
    , deduplicated as (
        select *
        from deduplicated_last_update
        where last_update = 1
    )
select *
from deduplicated