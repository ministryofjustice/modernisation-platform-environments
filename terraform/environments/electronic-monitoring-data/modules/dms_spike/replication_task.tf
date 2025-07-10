resource "aws_dms_replication_task" "dms_spike_replication_task" {
  replication_task_id      = "${var.dms_instance_id}-task"
  migration_type           = "full-load"
  replication_instance_arn = aws_dms_replication_instance.dms_spike_instance.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.dms_spike_source_endpoint.endpoint_arn
  target_endpoint_arn      = aws_dms_s3_endpoint.dms_spike_target_endpoint.endpoint_arn
  table_mappings           = var.table_mappings
 
  replication_task_settings = jsonencode(
    {
      Logging = {
        EnableLogging = true,
        EnableLogContext = true,
        LogComponents  = [
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "TRANSFORMATION"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "SOURCE_UNLOAD"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "IO"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "TARGET_LOAD"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "PERFORMANCE"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "SOURCE_CAPTURE"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "SORTER"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "REST_SERVER"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "VALIDATOR_EXT"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "TARGET_APPLY"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "TASK_MANAGER"
        },
        {
            Severity =  "LOGGER_SEVERITY_DEFAULT",
            Id =  "TABLES_MANAGER"
        },
    ],

      },
      ValidationSettings = {
        EnableValidation = true,
        ValidationMode = "GROUP_LEVEL",
        ThreadCount = 2,
        TableFailureMaxCount = 5,
        RecordFailureDelayLimitInMinutes = 5,
      }
    }
  )

}
