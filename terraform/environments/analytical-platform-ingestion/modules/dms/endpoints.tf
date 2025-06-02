data "aws_region" "current" {}

# DMS Source Endpoint
resource "aws_dms_endpoint" "source" {
  #checkov:skip=CKV_AWS_296: Use AWS managed KMS key
  endpoint_id   = "${var.db}-source-${data.aws_region.current.name}-${var.environment}"
  endpoint_type = "source"
  engine_name   = var.dms_source.engine_name

  secrets_manager_arn             = var.dms_source.secrets_manager_arn
  secrets_manager_access_role_arn = aws_iam_role.dms_source.arn
  database_name                   = var.dms_source.sid
  extra_connection_attributes     = var.dms_source.extra_connection_attributes

  tags = merge(
    { Name = "${var.db}-source-${data.aws_region.current.name}-${var.environment}" },
    var.tags
  )
}

# DMS S3 Target Endpoint
resource "aws_dms_s3_endpoint" "s3_target" {
  # checkov:skip=CKV_AWS_298: Use AWS managed KMS key
  endpoint_id                      = "${var.db}-target-${data.aws_region.current.name}-${var.environment}"
  endpoint_type                    = "target"
  bucket_name                      = aws_s3_bucket.landing.bucket
  bucket_folder                    = var.dms_target_prefix
  service_access_role_arn          = aws_iam_role.dms.arn
  add_column_name                  = var.s3_target_config.add_column_name
  canned_acl_for_objects           = "bucket-owner-full-control"
  cdc_max_batch_interval           = var.s3_target_config.max_batch_interval
  cdc_min_file_size                = var.s3_target_config.min_file_size
  compression_type                 = "GZIP"
  data_format                      = "parquet"
  encoding_type                    = "rle-dictionary"
  encryption_mode                  = "SSE_S3"
  include_op_for_full_load         = true
  parquet_timestamp_in_millisecond = true
  parquet_version                  = "parquet-2-0"
  timestamp_column_name            = var.s3_target_config.timestamp_column_name

  tags = merge(
    { Name = "${var.db}-target-${data.aws_region.current.name}-${var.environment}" },
    var.tags
  )
}
