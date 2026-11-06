# Shared S3 bucket for access logs from every load balancer in the feasibility account.

module "s3_lb_access_logs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name        = local.lb_access_logs_bucket_name
  versioning_enabled = false

  # ALB access logs only support SSE-S3
  sse_algorithm  = "AES256"
  custom_kms_key = ""

  bucket_policy = [data.aws_iam_policy_document.lb_access_logs.json]

  replication_enabled = false
  replication_region  = "eu-west-2"

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "lb-access-logs"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = local.application_data.accounts[local.environment].lb_access_logs_retention_days
      }

      noncurrent_version_expiration = {
        days = 7
      }

      abort_incomplete_multipart_upload_days = 7
    },
    {
      id      = "athena-results"
      enabled = "Enabled"
      prefix  = "athena-results/"

      tags = {
        rule      = "athena-results"
        autoclean = "true"
      }

      expiration = {
        days = local.application_data.accounts[local.environment].athena_results_retention_days
      }

      noncurrent_version_expiration = {
        days = 7
      }

      abort_incomplete_multipart_upload_days = 7
    }
  ]

  tags = merge(local.tags, {
    Name = local.lb_access_logs_bucket_name
  })
}

data "aws_iam_policy_document" "lb_access_logs" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${local.lb_access_logs_bucket_name}", "arn:aws:s3:::${local.lb_access_logs_bucket_name}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "DenyTLSOlderThan12"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${local.lb_access_logs_bucket_name}", "arn:aws:s3:::${local.lb_access_logs_bucket_name}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }

  statement {
    sid       = "AllowALBLogDelivery"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.lb_access_logs_bucket_name}/*/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::652711504416:root"] # ELB account for eu-west-2
    }
  }

  statement {
    sid       = "AllowALBLogDeliveryServicePrincipal"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.lb_access_logs_bucket_name}/*/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
  }

  # NLB log delivery goes through the CloudWatch Logs delivery service
  statement {
    sid       = "AllowNLBLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.lb_access_logs_bucket_name}/*/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid       = "AllowNLBLogDeliveryAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.lb_access_logs_bucket_name}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}
