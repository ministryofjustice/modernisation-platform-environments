resource "aws_kms_key" "export" {
  description             = "KMS key for RDS export"
  deletion_window_in_days = 7

  tags = local.tags
}

module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=sql-backup-restore"

  kms_key_arn = aws_kms_key.export.arn
  name = "${local.application_name}-${local.environment}"
  vpc_id = module.vpc.vpc_id
  database_subnet_ids = module.vpc.private_subnets

  tags = {
    business-unit = "HMPPS"
    application   = "property-cafm-data-migration"
    is-production = "false"
    owner         = "jyotiranjan.nayak@justice.gov.uk"
  }
}

# Create an S3 bucket for SFTP storage
resource "aws_s3_bucket" "sftp_bucket" {
  bucket = "property-datahub-landing-${local.environment}"
}

resource "aws_s3_bucket_public_access_block" "sftp_bucket" {
  bucket = aws_s3_bucket.sftp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

