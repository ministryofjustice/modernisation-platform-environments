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