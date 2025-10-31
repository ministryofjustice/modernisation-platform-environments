######################################
# KMS keys for CloudWatch Log Groups
######################################
resource "aws_kms_key" "cloudwatch_logs_key" {
  description         = "KMS key to be used for encrypting the CloudWatch logs in the Log Groups"
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_kms_alias" "cloudwatch_logs_key" {
  name          = "alias/${local.application_name}-cloudwatch-logs-kms"
  target_key_id = aws_kms_key.cloudwatch_logs_key.key_id
}

resource "aws_kms_key_policy" "cloudwatch_logs_policy" {
  key_id = aws_kms_key.cloudwatch_logs_key.id
  policy = jsonencode({
    Id = "key-default-1"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.env_account_id}:root"
        }

        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
      {
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Effect = "Allow"
        Principal = {
          Service = "logs.eu-west-2.amazonaws.com"
        }
        Resource = "*"
        Sid      = "Enable log service Permissions"
      }
    ]
    Version = "2012-10-17"
  })
}