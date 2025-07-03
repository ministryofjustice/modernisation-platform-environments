resource "aws_dms_replication_task" "dms_spike_replication_task" {
  replication_task_id      = "${var.dms_instance_id}-task"
  migration_type           = "full-load"
  replication_instance_arn = aws_dms_replication_instance.dms_spike_instance.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.dms_spike_source_endpoint.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.dms_spike_target_endpoint.endpoint_arn
  table_mappings           = var.table_mappings

  replication_task_settings = jsonencode(
    {
      Logging = {
        "EnableLogging" : true,
        "LogComponents" : [
          {
            "Id" : "SOURCE_CAPTURE",
            "Severity" : "LOGGER_SEVERITY_DEFAULT"
          },
          {
            "Id" : "SOURCE_UNLOAD",
            "Severity" : "LOGGER_SEVERITY_DEFAULT"
          },
          {
            "Id" : "TARGET_APPLY",
            "Severity" : "LOGGER_SEVERITY_DEFAULT"
          },
          {
            "Id" : "TARGET_LOAD",
            "Severity" : "LOGGER_SEVERITY_DEFAULT"
          },
          {
            "Id" : "TRANSFORMATION",
            "Severity" : "LOGGER_SEVERITY_DEBUG"
          },
          {
            "Id" : "VALIDATOR",
            "Severity" : "LOGGER_SEVERITY_DEFAULT"
          }
        ],
      }
      "ValidationSettings" : {
        "EnableValidation" : true,
        "ValidationMode" : "table-level",
        "ThreadCount" : 2,
        "TableFailureMaxCount" : 5,
        "RecordFailureDelayLimitInMinutes" : 5,
      }
    }
  )

}
