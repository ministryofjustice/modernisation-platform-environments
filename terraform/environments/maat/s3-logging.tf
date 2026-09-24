module "s3-bucket-logging" {
  # v11.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/81230d03816f140ae912454815ec531d7cbe2c8e
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=81230d03816f140ae912454815ec531d7cbe2c8e" # v11.2.0

  bucket_name        = "${local.application_name}-${local.environment}-logging"
  versioning_enabled = true
  bucket_policy = [
    aws_s3_bucket_policy.s3_access_logs.policy
  ]
  sse_algorithm  = "AES256"
  custom_kms_key = ""
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket-replication-role.role.arn
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

      expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current_logs
      }

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent_logs
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-logging" }
  )
}

data "aws_iam_policy_document" "s3_access_logs_policy" {
  # default statements - deny insecure transport and tls < 1.2
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "${module.s3-bucket-logging.bucket.arn}/*",
      module.s3-bucket-logging.bucket.arn
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  statement {
    sid     = "EnforceTLSv12orHigher"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "${module.s3-bucket-logging.bucket.arn}/*",
      module.s3-bucket-logging.bucket.arn
    ]
    condition {
      test     = "NumericLessThan"
      variable = "aws:TLSVersion"
      values   = ["1.2"]
    }
  }

  # Per-Bucket Statements
  ## Shared Bucket
  statement {
    sid     = "AllowS3Logging Shared Bucket"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "${module.s3-bucket-logging.bucket.arn}/*",
      module.s3-bucket-logging.bucket.arn
    ]
    condition {
      test = "StringLike"
      variable = "aws:SourceArn"
      values   = [module.s3-bucket-shared.bucket.arn]
    }
  }
  ## Athena Queries Bucket
  statement {
    sid     = "AllowS3Logging Athena Queries Bucket"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "${module.s3-bucket-logging.bucket.arn}/*",
      module.s3-bucket-logging.bucket.arn
    ]
    condition {
      test = "StringLike"
      variable = "aws:SourceArn"
      values   = [module.s3-bucket-athena-queries-output.bucket.arn]
    }
  }
  ## Artifacts Bucket
  statement {
    sid     = "AllowS3Logging Artifacts Bucket"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "${module.s3-bucket-logging.bucket.arn}/*",
      module.s3-bucket-logging.bucket.arn
    ]
    condition {
      test = "StringLike"
      variable = "aws:SourceArn"
      values   = [module.artifacts-s3.bucket.arn]
    }
  }
  ## Cloudfront Logging Bucket
  statement {
    sid     = "AllowS3Logging Cloudfront Logging Bucket"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "${module.s3-bucket-logging.bucket.arn}/*",
      module.s3-bucket-logging.bucket.arn
    ]
    condition {
      test = "StringLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.cloudfront.arn]
    }
  }
  ## Loadbalancer Logging Bucket
  statement {
    sid     = "AllowS3Logging Loadbalancer Logging Bucket"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "${module.s3-bucket-logging.bucket.arn}/*",
      module.s3-bucket-logging.bucket.arn
    ]
    condition {
      test = "StringLike"
      variable = "aws:SourceArn"
      values   = [module.lb-s3-access-logs.bucket.arn]
    }
  }

}

resource "aws_s3_bucket_policy" "s3_access_logs" {
    bucket = module.s3-bucket-logging.bucket.id
    policy = data.aws_iam_policy_document.s3_access_logs_policy.json
}