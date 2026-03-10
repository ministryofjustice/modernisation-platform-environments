data "aws_iam_policy_document" "logging_bucket_policy" {
  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.s3_bucket_logs.bucket.arn}/call-centre-staging/AWSLogs/*"]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

# bucket names for landing, archive, ingestion and curated
variable "bucket_prefixes" {
  description = "Bucket prefixes for raw-hist and curated buckets"
  type        = list(string)
  default     = ["call-centre-landing-", "call-centre-archive-", "call-centre-ingestion-", "call-centre-curated-"]
}

# tfsec:ignore:aws-s3-enable-logging - This is the logging bucket where logs are sent to
module "s3_bucket_logs" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix      = "call-centre-logs"
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"
  bucket_policy      = [data.aws_iam_policy_document.logging_bucket_policy.json]

  tags = local.tags
}


#tfsec:ignore:aws-s3-enable-logging - Logging is enabled on the bucket in the next resource
module "s3_buckets" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  for_each = toset(var.bucket_prefixes)

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix      = each.value
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  tags = local.tags
}

# tfsec:ignore:aws-s3-enable-logging - Logging is enabled on the bucket in the next resource
module "s3_bucket_staging" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix      = "call-centre-staging-"
  versioning_enabled = true
  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"
  acl                = "private"

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

      expiration = {
        days = 90
      }
    }
  ]


  tags = local.tags
}

# Enable bucket server logging for the staging bucket
resource "aws_s3_bucket_logging" "staging_bucket_logging" {
  bucket = module.s3_bucket_staging.bucket.id

  target_bucket = module.s3_bucket_logs.bucket.id
  target_prefix = "call-centre-staging"
}


module "s3-quarantine-files-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  bucket_prefix      = "call-centre-quarantined-"
  versioning_enabled = true

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"
  acl                = "private"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
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

      expiration = {
        days = 90
      }
    }
  ]

  tags = local.tags
}

module "s3-clamav-definitions-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  bucket_prefix      = "call-centre-clamav-definitions-"
  versioning_enabled = true

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"
  acl                = "private"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
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

      expiration = {
        days = 90
      }
    }
  ]

  tags = local.tags
}
