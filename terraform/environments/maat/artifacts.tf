module "artifacts-s3" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-build-artifacts"
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = true
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 31
      }

      noncurrent_version_expiration = {
        days = 31
      }
    }
  ]

  tags = local.tags
}

