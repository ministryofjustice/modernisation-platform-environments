locals {
  bucket_prefix_name = regex("^(.*?)-\\d{14}[a-zA-Z0-9]{12}$", var.source_bucket_name)[0]
}

# tfsec:ignore:aws-s3-enable-logging - This is the logging bucket where logs are sent to
module "log_bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  bucket_prefix      = "${bucket_prefix_name}-logs-"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"
  bucket_policy      = [data.aws_iam_policy_document.log_bucket_policy.json]

  tags = var.local_tags
}

data "aws_iam_policy_document" "log_bucket_policy" {
  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.log_bucket.bucket.arn}/${local.bucket_prefix_name}/AWSLogs/*"]

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

# Enable bucket server logging for the staging bucket
resource "aws_s3_bucket_logging" "staging_bucket_logging" {
  bucket = var.source_bucket_id

  target_bucket = module.log_buckets.bucket.id
  target_prefix = "logs/"
}
