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
        "Condition" : {
          "StringEquals" : {
            "kms:EncryptionContext:aws:logs:arn" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current_xsiam.account_id}:log-group:yjaf-${var.environment}-firehose-xsiam-error-logs"
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