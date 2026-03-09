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

# bucket names for landing, archive, ingestion annd curated
variable "bucket_prefixes" {
  description = "Bucket prefixes for raw-hist and curated buckets"
  type        = list(string)
  default     = ["raw-hist", "curated"]
}

# tfsec:ignore:aws-s3-enable-logging - This is the logging bucket where logs are sent to
module "s3_bucket_logs" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix      = "logs"
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"
  bucket_policy      = [data.aws_iam_policy_document.logging_bucket_policy.json]

  tags = local.tags
}

# tfsec:ignore:aws-s3-enable-logging - Logging is enabled on the bucket in the next resource
module "s3_bucket_land" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix      = "land"
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  tags = local.tags
}

#tfsec:ignore:aws-s3-enable-logging - Logging is enabled on the bucket in the next resource
module "s3_bucket_rawhist_curated" {
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

# Enable bucket server logging for the land bucket
resource "aws_s3_bucket_logging" "land_bucket_logging" {
  bucket = module.s3_bucket_land.bucket.id

  target_bucket = module.s3_bucket_logs.bucket.id
  target_prefix = "land"
}

# Data source for the member-access IAM role
# This is created by the mod platform team
data "aws_iam_role" "guardduty_malware_protection_role" {
  name = "GuardDutyS3MalwareProtectionRole"
}

# Create guardduty malware protection plan for the land bucket
resource "aws_guardduty_malware_protection_plan" "s3_bucket_land" {
  role = data.aws_iam_role.guardduty_malware_protection_role.arn

  protected_resource {
    s3_bucket {
      bucket_name = module.s3_bucket_land.bucket.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = local.tags
}
