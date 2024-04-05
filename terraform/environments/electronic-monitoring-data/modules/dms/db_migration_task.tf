# Create a new replication task
resource "aws_dms_replication_task" "dms-db-migration-task" {
  # cdc_start_time            = "1993-05-21T05:50:00Z"
  migration_type            = "full-load"
  replication_instance_arn  = var.dms_replication_instance_arn
  replication_task_id       = "${var.database_name}-db-migration-task-tf"
  replication_task_settings = var.rep_task_settings_filepath
  source_endpoint_arn       = aws_dms_endpoint.dms-rds-source.endpoint_arn
  table_mappings            = var.rep_task_table_mapping_filepath
  target_endpoint_arn       = aws_dms_s3_endpoint.dms-s3-parquet-target.endpoint_arn

  tags = merge(
    var.local_tags,
    {
      Resource_Type = "DMS Database Migration Task",
    },
  )
}

resource "null_resource" "dms_start_replicating" {
  triggers = {
    dms_task_arn = aws_dms_replication_task.dms-db-migration-task.replication_task_arn # aws_dms_replication_task.example.replication_task_arn
  }
  provisioner "local-exec" {
    when    = create
    command = "aws dms start-replication-task --start-replication-task-type start-replication --replication-task-arn ${self.triggers["dms_task_arn"]}"
  }

}
