resource "aws_kinesis_firehose_delivery_stream" "this" {
  count = local.is-production ? 1 : 0

  name        = local.component_name
  destination = "extended_s3"

  server_side_encryption {
    enabled  = true
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = module.destination_kms_key[0].key_arn
  }

  extended_s3_configuration {
    role_arn            = module.firehose_iam_role[0].arn
    bucket_arn          = module.s3_bucket[0].s3_bucket_arn
    buffering_interval  = 300
    buffering_size      = 5
    compression_format  = "GZIP"
    kms_key_arn         = module.destination_kms_key[0].key_arn
    prefix              = "raw/"
    error_output_prefix = "errors/!{firehose:error-output-type}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = module.firehose_cloudwatch_log_group[0].cloudwatch_log_group_name
      log_stream_name = aws_cloudwatch_log_stream.firehose[0].name
    }
  }
}
