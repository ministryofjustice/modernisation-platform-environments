# Data source for organization information
data "aws_organizations_organization" "root_account" {}

# DFI Report bucket for document and file storage
# checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
module "s3-dfi-report-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  count = var.dfi_report_bucket_config != null ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"
  providers = {
    aws                    = aws
    aws.bucket-replication = aws
  }

  bucket_prefix      = "delius-mis-${var.env_name}-dfi-report-"
  versioning_enabled = false
  bucket_policy      = var.dfi_report_bucket_config.bucket_policy_enabled ? [data.aws_iam_policy_document.dfi_report_bucket_policy[0].json] : []
  force_destroy      = true

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
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 365
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

data "aws_iam_policy_document" "dfi_report_bucket_policy" {
  count = var.dfi_report_bucket_config != null && var.dfi_report_bucket_config.bucket_policy_enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "${module.s3-dfi-report-bucket[0].bucket.arn}/*",
      module.s3-dfi-report-bucket[0].bucket.arn
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = ["${data.aws_organizations_organization.root_account.id}/*/${var.platform_vars.environment_management.modernisation_platform_organisation_unit_id}/*"]
    }
  }
}

module "s3_lb_logs_bucket" {
  count  = var.lb_config != null ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"
  providers = {
    aws                    = aws
    aws.bucket-replication = aws
  }

  bucket_prefix      = "delius-mis-${var.env_name}-lb-logs-"
  versioning_enabled = false
  bucket_policy      = var.lb_config.bucket_policy_enabled ? [data.aws_iam_policy_document.s3_lb_logs_bucket_policy[0].json] : []
  force_destroy      = true

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
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 365
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

# Get ELB service account for current region
data "aws_elb_service_account" "main" {
  count = var.lb_config != null && var.lb_config.bucket_policy_enabled ? 1 : 0
}

data "aws_iam_policy_document" "s3_lb_logs_bucket_policy" {
  count = var.lb_config != null && var.lb_config.bucket_policy_enabled ? 1 : 0

  # Allow ALB service account to write access logs
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.s3_lb_logs_bucket[0].bucket.arn}/*"
    ]
    principals {
      type = "AWS"
      # ELB service account for current region
      identifiers = [data.aws_elb_service_account.main[0].arn]
    }
  }

  # Allow ALB service account to check bucket ACL
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      module.s3_lb_logs_bucket[0].bucket.arn
    ]
    principals {
      type = "AWS"
      # ELB service account for current region
      identifiers = [data.aws_elb_service_account.main[0].arn]
    }
  }

  # Original policy for organization access
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "${module.s3_lb_logs_bucket[0].bucket.arn}/*",
      module.s3_lb_logs_bucket[0].bucket.arn
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = ["${data.aws_organizations_organization.root_account.id}/*/${var.platform_vars.environment_management.modernisation_platform_organisation_unit_id}/*"]
    }
  }
}
