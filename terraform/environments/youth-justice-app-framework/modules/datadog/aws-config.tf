### MOJ HAS ALREADY SETUP AWS CONFIG RECORDER AND SNS TOPIC ####

#module "datadog-aws-config" {
#  source                       = "DataDog/config-changes-datadog/aws"
#  version                      = "1.0.0"
#  dd_api_key_secret_arn        =  aws_secretsmanager_secret.datadog_api.arn
#  dd_integration_role_name     = "DatadogAWSIntegrationRole"
#  dd_destination_url           = "https://cloudplatform-intake.datadoghq.eu/api/v2/cloudchanges?dd-protocol=aws-kinesis-firehose"
#  sns_topic_name               = "aws-config-topic"
#  s3_bucket_name               = "yjaf-${var.environment}-awsconfig-datadog"
#  failed_events_s3_bucket_name = "yjaf-${var.environment}-awsconfig-failed-events"
#  tags = {
#    "team" = "AWS"
#  }
#}

resource "aws_kinesis_firehose_delivery_stream" "awsconfig_to_datadog" {
  #checkov:skip=CKV_AWS_241: todo 
  name        = "awsconfig-to-datadog"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://cloudplatform-intake.datadoghq.eu/api/v2/cloudchanges?dd-protocol=aws-kinesis-firehose"
    name               = "Datadog"
    buffering_interval = 60
    buffering_size     = 4
    role_arn           = aws_iam_role.awsconfig_firehose_to_datadog.arn

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.awsconfig_firehose_log_group.name
      log_stream_name = "awsconfig-datadog-http"
    }

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_backup_mode = "AllData"
    s3_configuration {
      role_arn           = aws_iam_role.awsconfig_firehose_to_datadog.arn
      bucket_arn         = aws_s3_bucket.awsconfig_firehose_backup.arn
      buffering_interval = 60
      buffering_size     = 5
      compression_format = "GZIP"
    }

    secrets_manager_configuration {
      enabled    = true
      role_arn   = aws_iam_role.awsconfig_firehose_to_datadog.arn
      secret_arn = aws_secretsmanager_secret.datadog_api.arn
    }
  }

  server_side_encryption {
    enabled  = true
    key_arn  = aws_kms_key.awsconfig_firehose_backup.arn
    key_type = "CUSTOMER_MANAGED_CMK"
  }
}

resource "aws_kms_key" "awsconfig_firehose_backup" {
  description             = "KMS key for encrypting Firehose S3 backup bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Create an alias for easier identification
resource "aws_kms_alias" "config_firehose_kms_alias" {
  name          = "alias/config-firehose-s3-backup-key"
  target_key_id = aws_kms_key.awsconfig_firehose_backup.key_id
}

resource "aws_kms_key_policy" "awsconfig_firehose_backup_policy" {
  key_id = aws_kms_key.awsconfig_firehose_backup.id

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
          AWS = aws_iam_role.awsconfig_firehose_to_datadog.arn
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

resource "aws_iam_role" "awsconfig_firehose_to_datadog" {
  name = "awsconfig_firehose_to_datadog"

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


resource "aws_iam_policy" "awsconfig_firehose_policy" {
  name        = "awsconfig_FirehoseToDatadogPolicy"
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
          aws_cloudwatch_log_group.awsconfig_firehose_log_group.arn,
          aws_cloudwatch_log_stream.awsconfig_firehose_log_stream.arn
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
          aws_s3_bucket.awsconfig_firehose_backup.arn,
          "${aws_s3_bucket.awsconfig_firehose_backup.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "awsconfig_firehose_secrets_access" {
  name = "awsconfig_FirehoseSecretsAccess"

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

resource "aws_iam_policy" "awsconfig_firehose_kms_access" {
  name = "awsconfig_FirehoseToUseCMK"

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
          aws_kms_key.awsconfig_firehose_backup.arn,
          var.kms_key_arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "awsconfig_firehose_kms_secret_access" {
  name = "awsconfig_FirehoseKMSSecretsDecrypt"

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

resource "aws_iam_role" "awsconfig_sns_to_datadog" {
  name = "awsconfig_sns_datadog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "sns.amazonaws.com",
            "firehose.amazonaws.com"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "awsconfig_sns_policy" {
  name        = "awsconfig_sns_policy"
  description = "Allows SNS to publish to Firehose delivery stream"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "firehose:DescribeDeliveryStream",
          "firehose:ListDeliveryStreams",
          "firehose:ListTagsForDeliveryStream",
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = [
          "arn:aws:firehose:eu-west-2:${var.aws_account_id}:deliverystream/awsconfig-to-datadog"
        ]
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "awsconfig_firehose_policy_attach" {
  role       = aws_iam_role.awsconfig_firehose_to_datadog.name
  policy_arn = aws_iam_policy.awsconfig_firehose_policy.arn
}

resource "aws_iam_role_policy_attachment" "awsconfig_attach_secrets_access" {
  role       = aws_iam_role.awsconfig_firehose_to_datadog.name
  policy_arn = aws_iam_policy.awsconfig_firehose_secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "awsconfig_attach_kms_secret_access" {
  role       = aws_iam_role.awsconfig_firehose_to_datadog.name
  policy_arn = aws_iam_policy.awsconfig_firehose_kms_secret_access.arn
}

resource "aws_iam_role_policy_attachment" "awsconfig_attach_kms_access" {
  role       = aws_iam_role.awsconfig_firehose_to_datadog.name
  policy_arn = aws_iam_policy.awsconfig_firehose_kms_access.arn
}

resource "aws_iam_role_policy_attachment" "awsconfig_sns_policy_attach" {
  role       = aws_iam_role.awsconfig_sns_to_datadog.name
  policy_arn = aws_iam_policy.awsconfig_sns_policy.arn
}

resource "aws_cloudwatch_log_group" "awsconfig_firehose_log_group" {
  name              = "yjaf-${var.environment}-awsconfig-firehose-error-logs"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.awsconfig_firehose_backup.arn
}

resource "aws_cloudwatch_log_stream" "awsconfig_firehose_log_stream" {
  name           = "awsconfig-datadog-http"
  log_group_name = aws_cloudwatch_log_group.awsconfig_firehose_log_group.name
}

resource "aws_sns_topic_subscription" "datadog_config" {
  topic_arn             = "arn:aws:sns:eu-west-2:${var.aws_account_id}:config"
  protocol              = "firehose"
  endpoint              = aws_kinesis_firehose_delivery_stream.awsconfig_to_datadog.arn
  subscription_role_arn = aws_iam_role.awsconfig_sns_to_datadog.arn
}
