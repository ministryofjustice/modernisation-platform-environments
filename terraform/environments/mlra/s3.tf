#tfsec:ignore:AVD-AWS-0132:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
module "s3-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=568694e50e03630d99cb569eafa06a0b879a1239"

  bucket_prefix      = "athena-query-s3-bucket"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.bucket_policy.json]
  # Enable bucket to be destroyed when not empty
  force_destroy = true
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    aws.bucket-replication = aws
  }

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

  tags = merge(local.tags,
    { Name = lower(format("s3-bucket-%s-%s-athena", local.application_name, local.environment)) }
  )
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["${module.s3-bucket.bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["athena.amazonaws.com"]
    }
  }
}



