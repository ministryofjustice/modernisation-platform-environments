resource "aws_kinesis_firehose_delivery_stream" "to_datadog" {
  #checkov:skip=CKV_AWS_241: todo 
  name        = "cloudwatch-to-datadog"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://aws-kinesis-http-intake.logs.datadoghq.eu/v1/input"
    name               = "Datadog"
    buffering_interval = 60
    buffering_size     = 4
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
    enabled  = true
    key_arn  = aws_kms_key.firehose_backup.arn
    key_type = "CUSTOMER_MANAGED_CMK"
  }
}



resource "aws_kms_key" "firehose_backup" {
  description             = "KMS key for encrypting Firehose S3 backup bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Create an alias for easier identification
resource "aws_kms_alias" "firehose_kms_alias" {
  name          = "alias/firehose-s3-backup-key"
  target_key_id = aws_kms_key.firehose_backup.key_id
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

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "firehose-datadog-http"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
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
          "firehose:PutRecordBatch",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ],
        Resource = aws_kinesis_firehose_delivery_stream.to_datadog.arn
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "FirehoseToDatadogPolicy"
  description = "Allows Firehose to send data to Datadog, write logs, and access S3 for backups"

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
        Resource = [
          aws_cloudwatch_log_group.firehose_log_group.arn,
          aws_cloudwatch_log_stream.firehose_log_stream.arn
        ]
      },
      {
        Sid    = "CreateLogResources",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ],
        Resource = "*"
      },
      {
        Sid    = "s3Permissions",
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.firehose_backup.arn,
          "${aws_s3_bucket.firehose_backup.arn}/*"
        ]
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
        Resource = [
          aws_kms_key.firehose_backup.arn,
          var.kms_key_arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_kms_secret_access" {
  name = "FirehoseKMSSecretsDecrypt"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid : "DecryptSecretWithKMSKey",
        Effect   = "Allow",
        Action   = "kms:Decrypt",
        Resource = var.kms_key_arn, # this must match the KMS key that encrypts the secret
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.eu-west-2.amazonaws.com"
          }
        }
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

resource "aws_iam_role_policy_attachment" "attach_kms_secret_access" {
  role       = aws_iam_role.firehose_to_datadog.name
  policy_arn = aws_iam_policy.firehose_kms_secret_access.arn
}

###### log groups to stream

resource "aws_cloudwatch_log_subscription_filter" "userjourney" {
  count           = contains(["test", "preproduction", "production"], var.environment) ? 1 : 0
  name            = "firehose-subscription"
  log_group_name  = "yjaf-${var.environment}/user-journey"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.to_datadog.arn
  role_arn        = aws_iam_role.cw_logs_to_firehose.arn
}


###### sns topics to stream

#### iam role and permissions are made in aws-config.tf file

resource "aws_sns_topic_subscription" "datadog_securityhub-alarms" {
  topic_arn             = "arn:aws:sns:eu-west-2:${var.aws_account_id}:securityhub-alarms"
  protocol              = "firehose"
  endpoint              = aws_kinesis_firehose_delivery_stream.to_datadog.arn
  subscription_role_arn = aws_iam_role.awsconfig_sns_to_datadog.arn
}


resource "aws_sns_topic_subscription" "datadog_high-priority-alarms-topic" {
  topic_arn             = "arn:aws:sns:eu-west-2:${var.aws_account_id}:high-priority-alarms-topic"
  protocol              = "firehose"
  endpoint              = aws_kinesis_firehose_delivery_stream.to_datadog.arn
  subscription_role_arn = aws_iam_role.awsconfig_sns_to_datadog.arn
}

