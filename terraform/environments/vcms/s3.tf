module "vcms_testing_reports_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.1"

  bucket_prefix      = "${local.application_name}-${local.environment}-testing-reports-"
  versioning_enabled = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "archive-old-reports"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "archive"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA" # infrequent Access after 3 months
        },
        {
          days          = 365
          storage_class = "GLACIER"    # deep archive after 1 year
        }
      ]

      expiration = {
        days = 730 # permanent deletion after 2 years
      }
    }
  ]

  sse_algorithm  = "aws:kms"
  custom_kms_key = local.account_config.kms_keys.general_shared

  tags = local.tags
}
