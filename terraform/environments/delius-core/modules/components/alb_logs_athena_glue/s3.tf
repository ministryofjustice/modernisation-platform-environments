module "s3_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=76321e50b20f5c0d918cd45bdcf0b62049f5baf1" # v10.1.0
  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
  sse_algorithm        = "AES256"
  bucket_prefix        = "${var.application_name}-lb-logs"
  bucket_policy        = [data.aws_iam_policy_document.bucket_policy.json]
  replication_enabled  = false
  versioning_enabled   = var.s3_versioning
  force_destroy        = var.force_destroy_bucket
  lifecycle_rule       = var.access_logs_lifecycle_rule

  tags = { backup = false }
}

data "aws_iam_policy_document" "bucket_policy" {

  statement {
    sid     = "EnforceTLSv12orHigher"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      module.s3_bucket.bucket.arn,
      "${module.s3_bucket.bucket.arn}/*"
    ]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.weblogic_alb_access_logs.bucket.arn}/weblogic-${var.env_name}-access/AWSLogs/${var.account_number}/*",
      "${module.weblogic_alb_access_logs.bucket.arn}/weblogic-${var.env_name}-connection/AWSLogs/${var.account_number}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.default.arn]
    }
  }

  statement {
    effect = "Allow"
    sid    = "AWSLogDeliveryWrite"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.s3_bucket.bucket.arn}/weblogic-${var.env_name}-access/AWSLogs/*",
      "${module.s3_bucket.bucket.arn}/weblogic-${var.env_name}-connection/AWSLogs/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      module.s3_bucket.bucket.arn
    ]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}