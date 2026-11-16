module "s3_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=76321e50b20f5c0d918cd45bdcf0b62049f5baf1" # v10.1.0
  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
  sse_algorithm       = "AES256"
  bucket_prefix       = "${local.name}-lb-logs"
  bucket_policy       = [data.aws_iam_policy_document.bucket_policy.json]
  replication_enabled = false
  versioning_enabled  = var.s3_versioning
  force_destroy       = var.force_destroy_bucket
  lifecycle_rule      = var.access_logs_lifecycle_rule

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
    sid    = "AllowALBLogDelivery"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${module.s3_bucket.bucket.arn}/${local.name}-access/AWSLogs/${var.account_id}/*",
      "${module.s3_bucket.bucket.arn}/${local.name}-connection/AWSLogs/${var.account_id}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
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
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
  }
}