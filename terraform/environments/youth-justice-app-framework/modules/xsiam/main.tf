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



resource "aws_kms_key" "firehose_backup_xsiam" {
  description             = "KMS key for encrypting Firehose S3 backup bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Create an alias for easier identification
resource "aws_kms_alias" "firehose_kms_alias_xsiam" {
  name          = "alias/firehose-xsiam-s3-backup-key"
  target_key_id = aws_kms_key.firehose_backup_xsiam.key_id
}

resource "aws_kms_key_policy" "firehose_backup_xsiam_policy" {
  key_id = aws_kms_key.firehose_backup_xsiam.id

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
          AWS = aws_iam_role.firehose_xsiam.arn
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
        "Condition": {
          "StringEquals": {
            "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current_xsiam.account_id}:log-group:yjaf-${var.environment}-firehose-xsiam-error-logs"
    }
  }

      },
      {
        Sid    = "AllowAccountRootUserFullAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current_xsiam.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
}



resource "aws_cloudwatch_log_group" "firehose_log_group_xsiam" {
  name              = "yjaf-${var.environment}-firehose-xsiam-error-logs"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.firehose_backup_xsiam.arn
}

# Data source to get current account ID
data "aws_caller_identity" "current_xsiam" {}


resource "aws_iam_role" "cw_logs_to_firehose_xsiam" {
  name = "cw-logs-to-firehose-xsiam"

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

resource "aws_iam_role" "firehose_xsiam" {
  name = "firehose_xsiam"

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

resource "aws_iam_role_policy" "cw_logs_to_firehose_xsiam_policy" {
  name = "AllowCWLogsToWriteToFirehose"
  role = aws_iam_role.cw_logs_to_firehose_xsiam.id

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
        Resource = aws_kinesis_firehose_delivery_stream.xsiam.arn
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_policy_xsiam" {
  name        = "FirehoseToXsiamPolicy"
  description = "Allows Firehose to send data to Xsiam, write logs, and access S3 for backups"

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
        Resource = aws_cloudwatch_log_group.firehose_log_group_xsiam.arn
      },
      {
        Sid    = "cloudWatchLog",
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.firehose_log_group_xsiam.arn
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
          aws_s3_bucket.firehose_backup_xsiam.arn,
          "${aws_s3_bucket.firehose_backup_xsiam.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_secrets_access_xsiam" {
  name = "FirehoseSecretsAccessXsiam"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.xsiam_api.arn
      }
    ]
  })
}


resource "aws_iam_policy" "firehose_kms_access_xsiam" {
  name = "AllowFirehoseToUseCMKXsiam"

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
          aws_kms_key.firehose_backup_xsiam.arn,
          var.kms_key_arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_kms_secret_access_xsiam" {
  name = "FirehoseKMSSecretsDecryptXsiam"

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

resource "aws_iam_role_policy_attachment" "attach_kms_access_xsiam" {
  role       = aws_iam_role.firehose_xsiam.name
  policy_arn = aws_iam_policy.firehose_kms_access_xsiam.arn
}


resource "aws_iam_role_policy_attachment" "attach_firehose_policy_xsiam" {
  role       = aws_iam_role.firehose_xsiam.name
  policy_arn = aws_iam_policy.firehose_policy_xsiam.arn
}

resource "aws_iam_role_policy_attachment" "attach_secrets_access_xsiam" {
  role       = aws_iam_role.firehose_xsiam.name
  policy_arn = aws_iam_policy.firehose_secrets_access_xsiam.arn
}

resource "aws_iam_role_policy_attachment" "attach_kms_secret_access_xsiam" {
  role       = aws_iam_role.firehose_xsiam.name
  policy_arn = aws_iam_policy.firehose_kms_secret_access_xsiam.arn
}

###### log groups to stream

resource "aws_cloudwatch_log_subscription_filter" "userjourney" {
  count           = contains(["test", "preproduction", "production"], var.environment) ? 1 : 0
  name            = "firehose-subscription"
  log_group_name  = "yjaf-${var.environment}/user-journey"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.xsiam.arn
  role_arn        = aws_iam_role.cw_logs_to_firehose_xsiam.arn
}