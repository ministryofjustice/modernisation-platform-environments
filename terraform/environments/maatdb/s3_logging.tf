module "s3-bucket-logging" {
  # v11.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/81230d03816f140ae912454815ec531d7cbe2c8e
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=81230d03816f140ae912454815ec531d7cbe2c8e"

  bucket_name        = "${local.application_name}-${local.environment}-logging"
  versioning_enabled = true
  bucket_policy = [
    aws_s3_bucket_policy.lb_access_logs.policy
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

      transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_glacier
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
      }

      noncurrent_version_transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-logging" }
  )
}

data "aws_iam_policy_document" "lb_access_logs_policy" {
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
      test     = "StringLessThan"
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
      "${module.s3-bucket-shared.bucket.arn}/*",
      module.s3-bucket-shared.bucket.arn
    ]
  }

  ## FTP Buckets
  statement {
    sid     = "AllowS3Logging FTP Buckets"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = flatten([
      for bucket in values(module.s3_bucket) : [
        "${bucket.arn}/*",
        bucket.arn
      ]
    ])
  }
}

resource "aws_s3_bucket_policy" "lb_access_logs" {
    bucket = module.s3-bucket-logging.bucket.id
    policy = data.aws_iam_policy_document.lb_access_logs_policy.json
}
