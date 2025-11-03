locals {
  s3_access_logs_bucket_name = "mojdp-${local.environment}-s3-access-logs"
}

data "aws_iam_policy_document" "s3_access_logs_bucket_policy" {
  statement {
    sid       = "AllowS3ServerAccessLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.s3_access_logs_bucket_name}/*"]
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

#trivy:ignore:AVD-AWS-0132: S3 Server Access Logging bucket cannot use SSE-KMS (https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html)
module "s3_access_logs_s3_bucket" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=c375418373496865e2770ad8aabfaf849d4caee5" # v5.7.0

  bucket = local.s3_access_logs_bucket_name

  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_access_logs_bucket_policy.json

  object_lock_enabled = false

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    status = "Disabled"
  }
}
