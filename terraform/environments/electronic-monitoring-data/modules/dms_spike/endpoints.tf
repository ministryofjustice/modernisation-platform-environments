resource "aws_dms_endpoint" "dms_spike_source_endpoint" {
  endpoint_id   = "${var.dms_instance_id}-source"
  endpoint_type = "source"
  engine_name   = var.engine_name
  server_name   = var.server_name
  port          = var.port
  username      = var.username
  password      = var.password
  database_name = var.database_name
}

resource "aws_dms_s3_endpoint" "dms_spike_target_endpoint" {
  endpoint_id                      = "${var.dms_instance_id}-tagret"
  endpoint_type                    = "target"
  bucket_name                      = var.s3_bucket_name
  bucket_folder                    = "dms-spike-output/"
  data_format                      = "parquet"
  parquet_version                  = "parquet-2-0"
  timestamp_column_name            = "dms_spike_timestamp"
  date_partition_enabled           = true
  date_partition_sequence          = "YYYYMMDD"
  date_partition_delimiter         = "-"
  enable_statistics                = true
  parquet_timestamp_in_millisecond = true
  service_access_role_arn          = aws_iam_role.dms_spike_s3_access_role.arn
  add_column_name                  = true
}