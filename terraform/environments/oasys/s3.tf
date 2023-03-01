module "s3-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.3.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-${local.environment}-"
  replication_enabled = false

  bucket_policy = [data.aws_iam_policy_document.user-s3-access.json]


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

