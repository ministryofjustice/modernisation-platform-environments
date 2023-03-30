module "s3-bucket" { # need to backup files , then baseline this, then upload files
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.3.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-${local.environment}-"
  replication_enabled = false

  bucket_policy = [data.aws_iam_policy_document.user-s3-access.json]

  versioning_enabled = false

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Disabled"
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

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]
  tags = local.tags
}

