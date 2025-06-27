resource "aws_kms_key" "rds_export" {
  description             = "KMS key for RDS export"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = local.tags
}

resource "aws_kms_key_policy" "rds_export" {
  key_id = aws_kms_key.cloudwatch_logs_key.id
  policy = jsonencode({
    Id = "key-default-1"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.modernisation_platform_account_id}:root"
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


module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=sql-backup-restore"

  kms_key_arn = aws_kms_key.export.arn
  name = "cafm-${local.environment}"
  vpc_id = module.vpc.vpc_id
  database_subnet_ids = module.vpc.private_subnets

  tags = {
    business-unit = "HMPPS"
    application   = "property-cafm-data-migration"
    is-production = "false"
    owner         = "shanmugapriya.basker@justice.gov.uk"
  }
}
