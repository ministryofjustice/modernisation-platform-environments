# Data source for organization information
data "aws_organizations_organization" "root_account" {}

# DFI Report bucket for document and file storage
# checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
module "s3-dfi-report-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  count = var.dfi_report_bucket_config != null ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v11.1.1"
  providers = {
    aws                    = aws
    aws.bucket-replication = aws
  }

  bucket_prefix      = "delius-mis-${var.env_name}-dfi-report-"
  versioning_enabled = false
  bucket_policy      = var.dfi_report_bucket_config.bucket_policy_enabled ? [data.aws_iam_policy_document.dfi_report_bucket_policy[0].json] : []
  force_destroy      = true
  ownership_controls = "BucketOwnerEnforced"

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

data "aws_secretsmanager_secret_version" "dis_config" {
  count = var.dis_config != null ? 1 : 0

  secret_id = aws_secretsmanager_secret.dis_config.id
}

locals {
  # ensure dis config secret is populated and contains dfi_account_id
  dis_config_secret = length(data.aws_secretsmanager_secret_version.dis_config) == 1 ? data.aws_secretsmanager_secret_version.dis_config[0].secret_string : null
  dis_config_map    = local.dis_config_secret != null ? jsondecode(local.dis_config_secret) : null
  dfi_account_id    = local.dis_config_map != null ? nonsensitive(local.dis_config_map["dfi_account_id"]) : null
}

data "aws_iam_policy_document" "dfi_report_bucket_policy" {
  count = var.dfi_report_bucket_config == null ? 0 : var.dfi_report_bucket_config.bucket_policy_enabled ? 1 : 0

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

  dynamic "statement" {
    for_each = length(aws_iam_role.datasync_s3_role) == 1 ? [aws_iam_role.datasync_s3_role[0].arn] : []
    content {
      sid    = "DataSyncReadPolicy"
      effect = "Allow"
      actions = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:ListBucketVersions",
        "s3:GetBucketVersioning",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
        "s3:GetObjectAcl",
        "s3:GetObjectVersionAcl"
      ]
      resources = [
        "${module.s3-dfi-report-bucket[0].bucket.arn}/*",
        module.s3-dfi-report-bucket[0].bucket.arn
      ]
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
    }
  }

  dynamic "statement" {
    for_each = local.dfi_account_id != null ? [local.dfi_account_id] : []
    content {
      sid    = "DfiS3PutPolicy"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      resources = [
        "${module.s3-dfi-report-bucket[0].bucket.arn}/dfinterventions/dfi/*",
        module.s3-dfi-report-bucket[0].bucket.arn
      ]
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value}:root"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.dfi_account_id != null ? [local.dfi_account_id] : []
    content {
      sid    = "DfiS3ListPolicy"
      effect = "Allow"
      actions = [
        "s3:List*",
        "s3:DeleteObject*",
        "s3:GetObject*",
        "s3:GetBucketLocation"
      ]
      resources = [
        "${module.s3-dfi-report-bucket[0].bucket.arn}/dfinterventions/dfi/*",
        module.s3-dfi-report-bucket[0].bucket.arn
      ]
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value}:root"]
      }
    }
  }
}

module "s3_lb_logs_bucket" {
  count  = var.lb_config != null ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v11.1.1"
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
  count = var.lb_config == null ? 0 : var.lb_config.bucket_policy_enabled ? 1 : 0
}

data "aws_iam_policy_document" "s3_lb_logs_bucket_policy" {
  count = var.lb_config == null ? 0 : var.lb_config.bucket_policy_enabled ? 1 : 0

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
