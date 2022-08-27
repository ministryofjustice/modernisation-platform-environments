
module "wepi_s3_logging" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "wepi-logging"
  replication_enabled = false

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
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

resource "aws_s3_bucket_policy" "wepi_s3_logging_bucket_policy" {
  bucket = module.wepi_s3_logging.bucket.id
  policy = templatefile("${path.module}/json/wepi_s3_redshift_bucket_policy.json",
    {
      logging_bucket = module.wepi_s3_logging.bucket.arn
    }
  )
}