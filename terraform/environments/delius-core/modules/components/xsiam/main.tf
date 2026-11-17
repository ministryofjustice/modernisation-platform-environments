resource "aws_kinesis_firehose_delivery_stream" "xsiam" {
  name        = "${local.name}-firehose-xsiam"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = data.aws_secretsmanager_secret_version.xsiam_endpoint.secret_string
    name               = "XSIAM"
    buffering_interval = 60
    buffering_size     = 4
    role_arn           = aws_iam_role.firehose_xsiam.arn

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = var.log_group_name
      log_stream_name = var.log_stream_name
    }

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_backup_mode = "AllData"
    s3_configuration {
      role_arn           = aws_iam_role.firehose_xsiam.arn
      bucket_arn         = module.xsiam_s3_bucket.bucket.arn
      buffering_interval = 60
      buffering_size     = 5
      compression_format = "GZIP"
    }

    secrets_manager_configuration {
      enabled    = true
      role_arn   = aws_iam_role.firehose_xsiam.arn
      secret_arn = aws_secretsmanager_secret.xsiam_api.arn
    }
  }

  server_side_encryption {
    enabled  = true
    key_arn  = aws_kms_key.firehose_backup_xsiam.arn
    key_type = "CUSTOMER_MANAGED_CMK"
  }
}

resource "aws_cloudwatch_log_subscription_filter" "userjourney_to_xsiam" {
  name            = "${local.name}-xsiam-firehose-subscription"
  log_group_name  = var.log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.xsiam.arn
  role_arn        = aws_iam_role.cw_logs_to_firehose_xsiam.arn
}