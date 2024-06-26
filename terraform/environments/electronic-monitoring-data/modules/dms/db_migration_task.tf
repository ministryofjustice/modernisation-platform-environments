# Create a new replication task
resource "aws_dms_replication_task" "dms_db_migration_task" {

  migration_type            = "full-load"
  replication_instance_arn  = var.dms_replication_instance_arn
  replication_task_id       = "${replace(var.database_name, "_", "-")}-db-migration-task-tf"
  replication_task_settings = var.rep_task_settings_filepath
  source_endpoint_arn       = aws_dms_endpoint.dms_rds_source.endpoint_arn
  table_mappings            = var.rep_task_table_mapping_filepath
  target_endpoint_arn       = aws_dms_s3_endpoint.dms_s3_parquet_target.endpoint_arn

  tags = merge(
    var.local_tags,
    {
      Resource_Type = "DMS Database Migration Task without transformations",
    },
  )
}

resource "aws_dms_replication_task" "dms_db_migration_task_v2" {
  count = fileexists("${path.module}/dms_${var.database_name}_task_transformations.json") ? 1 : 0

  migration_type            = "full-load"
  replication_instance_arn  = var.dms_replication_instance_arn
  replication_task_id       = "${replace(var.database_name, "_", "-")}-db-migration-task-v2-tf"
  replication_task_settings = var.rep_task_settings_filepath
  source_endpoint_arn       = aws_dms_endpoint.dms_rds_source.endpoint_arn
  table_mappings            = trimspace(file("${path.module}/dms_${var.database_name}_task_transformations.json"))
  target_endpoint_arn       = aws_dms_s3_endpoint.dms_s3_parquet_target.endpoint_arn

  tags = merge(
    var.local_tags,
    {
      Resource_Type = "DMS Database Migration Task with transformations",
    },
  )
}