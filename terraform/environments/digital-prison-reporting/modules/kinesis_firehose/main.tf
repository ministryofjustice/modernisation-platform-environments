resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = var.name
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_source_stream_arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn       = aws_iam_role.firehose_role.arn
    bucket_arn     = var.target_s3_arn
    kms_key_arn    = var.target_s3_kms
    s3_backup_mode = "Disabled"
    buffering_size = var.buffering_size

    prefix              = var.target_s3_prefix
    error_output_prefix = var.target_s3_error_prefix

    cloudwatch_logging_options {
      enabled         = var.cloudwatch_logging_enabled
      log_group_name  = length(var.cloudwatch_log_group_name) > 0 ? var.cloudwatch_log_group_name : format("/aws/kinesisfirehose/%s", var.name)
      log_stream_name = var.cloudwatch_log_stream_name
    }
  }
}