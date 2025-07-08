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
        EnableLogging = true
      },
      ValidationSettings = {
        EnableValidation = true,
        ValidationMode = "ROW_LEVEL",
        ThreadCount = 2,
        TableFailureMaxCount = 5,
        RecordFailureDelayLimitInMinutes = 5,
      }
    }
  )

}
