resource "aws_kms_key" "shared" {
  description             = "Customer-managed KMS key for encrypting SNS topic"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  tags = {
    Purpose = "Shared key for S3 + CloudWatch"
  }
}

resource "aws_kms_key_policy" "shared_policy" {
  key_id = aws_kms_key.shared.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowRootAccountToManageKey",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = "kms:*",
        Resource = "*"
      }
    ]
  })
}
