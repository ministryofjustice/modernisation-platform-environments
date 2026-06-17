resource "aws_kms_key" "flow_logs" {
  count                   = contains(["development"], local.environment) ? 1 : 0
  description             = "KMS key for VPC Flow Logs encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = merge(local.extended_tags, {
    description = "KMS key for VPC Flow Logs encryption"
  })
}

resource "aws_kms_alias" "flow_logs" {
  count         = contains(["development"], local.environment) ? 1 : 0
  name          = "alias/${local.name}-flow-logs"
  target_key_id = aws_kms_key.flow_logs[0].key_id
}
