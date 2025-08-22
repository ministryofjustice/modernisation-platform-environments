resource "aws_kms_key" "sns_kms" {
  description             = "Customer-managed KMS key for encrypting SNS topic"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  tags = {
    Purpose = "SNS topic encryption"
  }
}

resource "aws_kms_key_policy" "sns_kms_policy" {
  key_id = aws_kms_key.sns_kms.id

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
