data "aws_iam_policy_document" "s3_access_logs_bucket_policy" {
  statement {
    sid       = "AllowS3ServerAccessLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::mojdp-${local.environment}-s3-access-logs/*"]
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

module "s3_access_logs_s3_bucket" {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=c375418373496865e2770ad8aabfaf849d4caee5" # v5.7.0

  bucket = "mojdp-${local.environment}-s3-access-logs"

  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_access_logs_bucket_policy.json

  object_lock_enabled = false

  versioning = {
    status = "Disabled"
  }
}

module "s3_access_logs_testing_s3_bucket" {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=c375418373496865e2770ad8aabfaf849d4caee5" # v5.7.0

  bucket = "mojdp-${local.environment}-s3-access-logs-testing"

  force_destroy = true

  logging = {
    target_bucket = module.s3_access_logs_s3_bucket.s3_bucket_id
    target_prefix = "${module.s3_access_logs_testing_s3_bucket.s3_bucket_id}/"
  }
}
