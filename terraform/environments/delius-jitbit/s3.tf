module "s3_bucket" {
  count = local.environment == "development" ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix      = "${local.application_name}-${local.environment}-"
  versioning_enabled = true

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
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

resource "aws_s3_bucket_intelligent_tiering_configuration" "jitbit_bucket_tiering" {
  bucket = module.s3_bucket[0].bucket.id
  name   = "JitbitBucketTiering"

  status = "Enabled"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 120
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}
