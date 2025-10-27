resource "aws_kinesis_firehose_delivery_stream" "xsiam" {
  #checkov:skip=CKV_AWS_241: todo 
  name        = "cloudwatch-to-xsiam"
  destination = "http_endpoint"

  depends_on = [
    aws_secretsmanager_secret.xsiam_api,
    aws_secretsmanager_secret.xsiam_endpoint,
    aws_iam_role.firehose_xsiam,
    aws_cloudwatch_log_group.firehose_log_group_xsiam,
    aws_s3_bucket.firehose_backup_xsiam,
    aws_kms_key.firehose_backup_xsiam
  ]

  http_endpoint_configuration {
    url                = data.aws_secretsmanager_secret_version.xsiam_endpoint.secret_string
    name               = "XSIAM"
    buffering_interval = 60
    buffering_size     = 4
    role_arn           = aws_iam_role.firehose_xsiam.arn

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group_xsiam.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream_xsiam.name
    }

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_backup_mode = "AllData"
    s3_configuration {
      role_arn           = aws_iam_role.firehose_xsiam.arn
      bucket_arn         = aws_s3_bucket.firehose_backup_xsiam.arn
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


resource "aws_cloudwatch_log_group" "firehose_log_group_xsiam" {
  name              = "yjaf-${var.environment}-firehose-xsiam-error-logs"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.firehose_backup_xsiam.arn
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream_xsiam" {
  name           = "firehose-xsiam-http"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group_xsiam.name
}

###### log groups to stream

resource "aws_cloudwatch_log_subscription_filter" "userjourney_to_xsiam" {
  count           = contains(["test", "preproduction", "production"], var.environment) ? 1 : 0
  name            = "xsiam-firehose-subscription"
  log_group_name  = "yjaf-${var.environment}/user-journey"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.xsiam.arn
  role_arn        = aws_iam_role.cw_logs_to_firehose_xsiam.arn
}

resource "aws_cloudwatch_log_subscription_filter" "directory_to_xsiam" {
  count           = contains(["test", "preproduction", "production"], var.environment) ? 1 : 0
  name            = "xsiam-firehose-subscription"
  log_group_name  = var.ds_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.xsiam.arn
  role_arn        = aws_iam_role.cw_logs_to_firehose_xsiam.arn
}


# Data source to get current account ID
data "aws_caller_identity" "current_xsiam" {}
