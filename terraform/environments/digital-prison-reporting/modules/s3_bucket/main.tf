locals {
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}s3"
      Resource_Type = "S3 Bucket"
    }
  )
}

provider "aws" {
  region = "eu-west-2"
}

module "s3-bucket" {
  count  = var.create_bucket ? 1 : 0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = var.name_prefix

  replication_enabled = false
  custom_kms_key      = var.aws_kms_arn
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