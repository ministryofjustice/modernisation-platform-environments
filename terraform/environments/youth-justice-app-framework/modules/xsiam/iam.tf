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
        Resource = [
          aws_cloudwatch_log_group.firehose_log_group_xsiam.arn,
          aws_cloudwatch_log_stream.firehose_log_stream_xsiam.arn
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