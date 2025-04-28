resource "aws_kinesis_firehose_delivery_stream" "to_datadog" {
  #checkov:skip=CKV_AWS_241: todo 
  name        = "cloudwatch-to-datadog"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://aws-kinesis-http-intake.logs.datadoghq.eu/v1/input"
    name               = "Datadog"
    access_key         = ""
    buffering_interval = 60
    buffering_size     = 1
    role_arn           = aws_iam_role.firehose_to_datadog.arn

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = "firehose-datadog-http"
    }

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_backup_mode = "AllData"
    s3_configuration {
      role_arn           = aws_iam_role.firehose_to_datadog.arn
      bucket_arn         = aws_s3_bucket.firehose_backup.arn
      buffering_interval = 60
      buffering_size     = 5
      compression_format = "GZIP"
    }

    secrets_manager_configuration {
      enabled    = true
      role_arn   = aws_iam_role.firehose_to_datadog.arn
      secret_arn = aws_secretsmanager_secret.datadog_api.arn
    }
  }
      
  server_side_encryption {
  enabled   = true
  key_arn   = aws_kms_key.firehose_backup.arn
  key_type  = "CUSTOMER_MANAGED_CMK"
 }
}



resource "aws_kms_key" "firehose_backup" {
  description             = "KMS key for encrypting Firehose S3 backup bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "firehose_backup_policy" {
  key_id = aws_kms_key.firehose_backup.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowFirehoseServiceAccess",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowFirehoseRoleAccess",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.firehose_to_datadog.arn
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsAccess",
        Effect = "Allow",
        Principal = {
          Service = "logs.eu-west-2.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowAccountRootUserFullAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
}



resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "yjaf-${var.environment}-firehose-error-logs"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.firehose_backup.arn
}

resource "aws_cloudwatch_log_subscription_filter" "cloudtrail" {
  name            = "firehose-subscription"
  log_group_name  = "cloudtrail"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.to_datadog.arn
  role_arn        = aws_iam_role.cw_logs_to_firehose.arn
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}


resource "aws_iam_role" "cw_logs_to_firehose" {
  name = "cw-logs-to-firehose"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "firehose_to_datadog" {
  name = "firehose_to_datadog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cw_logs_to_firehose_policy" {
  name = "AllowCWLogsToWriteToFirehose"
  role = aws_iam_role.cw_logs_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = aws_kinesis_firehose_delivery_stream.to_datadog.arn
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "FirehoseToDatadogPolicy"
  description = "Allows Firehose to send data to Datadog"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.firehose_log_group.arn
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_secrets_access" {
  name = "FirehoseSecretsAccess"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.datadog_api.arn
      }
    ]
  })
}


resource "aws_iam_policy" "firehose_kms_access" {
  name = "AllowFirehoseToUseCMK"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.firehose_backup.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kms_access" {
  role       = aws_iam_role.firehose_to_datadog.name
  policy_arn = aws_iam_policy.firehose_kms_access.arn
}


resource "aws_iam_role_policy_attachment" "firehose_policy_attach" {
  role       = aws_iam_role.firehose_to_datadog.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_secrets_access" {
  role       = aws_iam_role.firehose_to_datadog.name
  policy_arn = aws_iam_policy.firehose_secrets_access.arn
}