resource "aws_kms_key" "shared_kms_key" {
  description             = "Customer-managed KMS key for encrypting SNS topic"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  tags = {
    Purpose = "CAFM Shared Key for encryption"
  }
}

# Alias for the key
resource "aws_kms_alias" "shared_kms_key" {
  name          = "alias/${local.account_name}-shared-key-${local.environment_shorthand}"
  target_key_id = aws_kms_key.shared_kms_key.key_id
}

resource "aws_kms_key_policy" "shared_kms_key_policy" {
  key_id = aws_kms_key.shared_kms_key.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSNSUsage",
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowAccountAdmin",
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
