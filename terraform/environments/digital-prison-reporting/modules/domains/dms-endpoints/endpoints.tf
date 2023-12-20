# Create an endpoint for the source database
resource "aws_dms_endpoint" "dms-s3-target-source" {
  count = var.setup_dms_endpoints ? 1 : 0

  database_name = var.source_db_name
  endpoint_id   = "${var.project_id}-dms-${var.short_name}-${var.dms_source_name}-source-endpoint"
  endpoint_type = "source"
  engine_name   = var.source_engine_name
  password      = var.source_app_password
  port          = var.source_db_port
  server_name   = var.source_address
  ssl_mode      = "none"
  username      = var.source_app_username

  extra_connection_attributes = var.extra_attributes

  tags = (
  var.tags,
  {
    Resource_Type = "DMS Source Endpoint"
  })
}

resource "aws_dms_s3_endpoint" "dms-s3-target-endpoint" {
  count = var.setup_dms_endpoints ? 1 : 0

  endpoint_id                      = "${var.project_id}-dms-${var.short_name}-s3-target-endpoint"
  endpoint_type                    = "target"
  bucket_name                      = var.bucket_name
  service_access_role_arn          = aws_iam_role.dms-s3-role.arn
  data_format                      = "parquet"
  cdc_path                         = "cdc"
  timestamp_column_name            = "_timestamp"
  parquet_timestamp_in_millisecond = false
  include_op_for_full_load         = true

  max_file_size           = 120000
  cdc_max_batch_interval  = 10
  cdc_inserts_and_updates = true

  tags = (
  var.tags,
  {
    Resource_Type = "DMS Target Endpoint"
  })
}