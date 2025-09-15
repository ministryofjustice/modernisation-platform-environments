resource "aws_kms_key" "sns_sqs_key" {
  description             = "KMS key used to encrypt SQS queues that allow access to SNS topics"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-sns-sqs-key"
    }
  )
}

resource "aws_kms_key_policy" "sns_sqs_key_policy" {
  key_id = aws_kms_key.sns_sqs_key.id

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "sns-sqs-key",
    Statement = [
      {
        Sid    = "Allow access through Simple Queue Service (SQS) for all principals in the account that are authorized to use SQS",
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:ViaService"    = "sqs.eu-west-2.amazonaws.com",
            "kms:CallerAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        Sid    = "AllowSNSDirectUsage",
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        Sid    = "Allow direct access to key metadata to the account",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "kms:*"
        ],
        Resource = "*"
      }
    ]
  })
}
