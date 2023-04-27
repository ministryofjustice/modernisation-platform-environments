module "equip-s3-bucket" {
  count               = local.is-production ? 1 : 0
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"
  bucket_prefix       = format("%s-%s", local.application_name, local.environment)
  versioning_enabled  = false
  replication_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "tmp"
      enabled = "Enabled"
      prefix  = "/tmp"

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}