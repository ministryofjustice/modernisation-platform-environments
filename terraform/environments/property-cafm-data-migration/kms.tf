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
        Sid = "AllowSNSUsage",
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
        Sid = "AllowAccountAccess",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/sandbox",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/migration",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/migration"
          ]
        },
        Action = "kms:*",
        Resource = "*"
      }
    ]
  })
}
