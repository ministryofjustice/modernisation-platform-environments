provider "aws" {
  alias  = "bucket-replication"
  region = "eu-west-1"
}
module "s3-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v4.0.0"

  providers = {
    aws.bucket-replication = aws.eu-west-2
  }
  bucket_prefix        = "s3-bucket"
  replication_role_arn = module.s3-bucket-replication-role.role.arn
  replication_enabled = true

  lifecycle_rule = [
    {
      id      = "main"
      enabled = true
      prefix  = ""

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

  tags                 = local.tags
}
