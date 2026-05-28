locals {
  alb_access_logs_bucket_name = "mojdp-${local.environment}-${local.component_name}-alb-logs"
}

data "aws_elb_service_account" "current" {}

data "aws_iam_policy_document" "alb_access_logs_bucket_policy" {
  statement {
    sid       = "AllowALBPutObject"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.alb_access_logs_bucket_name}/${local.component_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }
  }
}

#trivy:ignore:AVD-AWS-0132: ALB access log buckets cannot use SSE-KMS (https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html)
module "alb_access_logs" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=af0286ff37a66c2b79faf360e6e2663744b8e5b5" # v5.13.0

  bucket = local.alb_access_logs_bucket_name

  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.alb_access_logs_bucket_policy.json

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

  lifecycle_rule = [
    {
      id      = "expire-alb-access-logs"
      enabled = true

      expiration = {
        days = 90
      }
    }
  ]
}
