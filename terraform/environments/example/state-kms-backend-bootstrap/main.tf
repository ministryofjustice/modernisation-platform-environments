# Temporary canary for validating strict SSE-KMS Terraform backend writes.
# Remove after the modernisation-platform-terraform-state remediation is proven.

locals {
  state_kms_backend_canary_alias_name  = "alias/example-terraform-state-kms-backend-canary"
  state_kms_backend_canary_bucket_name = "example-development-terraform-state-kms-backend-canary"
  tags = {
    application      = "example"
    environment-name = terraform.workspace
    is-production    = false
    source-code      = "https://github.com/ministryofjustice/modernisation-platform-environments"
    temporary        = "true"
  }
}

data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "root_account" {}

data "aws_region" "current" {}

resource "aws_kms_key" "state_kms_backend_canary" {
  description             = "Temporary SSE-KMS Terraform backend canary key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.state_kms_backend_canary_key.json
}

resource "aws_kms_alias" "state_kms_backend_canary" {
  name          = local.state_kms_backend_canary_alias_name
  target_key_id = aws_kms_key.state_kms_backend_canary.id
}

data "aws_iam_policy_document" "state_kms_backend_canary_key" {
  # checkov:skip=CKV_AWS_109: Mirrors the Modernisation Platform state bucket key policy for canary testing.
  # checkov:skip=CKV_AWS_111: KMS key policies require wildcard resources for key permissions.
  # checkov:skip=CKV_AWS_356: KMS key policies require wildcard resources for key permissions.
  statement {
    sid    = "AllowManagementAccessFromExampleAccount"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "ReadOnlyFromModernisationPlatformOU"
    effect = "Allow"
    actions = [
      "kms:Decrypt*"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = ["${data.aws_organizations_organization.root_account.id}/*/${var.modernisation_platform_organisation_unit_id}/*"]
    }
  }

  statement {
    sid    = "AllowTerraformStateBucketUseFromModernisationPlatformOU"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = ["${data.aws_organizations_organization.root_account.id}/*/${var.modernisation_platform_organisation_unit_id}/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${aws_s3_bucket.state_kms_backend_canary.arn}/*"]
    }
  }
}

resource "aws_s3_bucket" "state_kms_backend_canary" {
  bucket        = local.state_kms_backend_canary_bucket_name
  force_destroy = true

  tags = merge(local.tags, {
    Name    = local.state_kms_backend_canary_bucket_name
    purpose = "terraform-state-sse-kms-backend-canary"
  })
}

resource "aws_s3_bucket_public_access_block" "state_kms_backend_canary" {
  bucket = aws_s3_bucket.state_kms_backend_canary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state_kms_backend_canary" {
  bucket = aws_s3_bucket.state_kms_backend_canary.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state_kms_backend_canary" {
  bucket = aws_s3_bucket.state_kms_backend_canary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_kms_backend_canary" {
  bucket = aws_s3_bucket.state_kms_backend_canary.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_kms_backend_canary.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "state_kms_backend_canary" {
  bucket = aws_s3_bucket.state_kms_backend_canary.id
  policy = data.aws_iam_policy_document.state_kms_backend_canary_bucket.json
}

data "aws_iam_policy_document" "state_kms_backend_canary_bucket" {
  statement {
    sid    = "AllowCanaryWriterListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.state_kms_backend_canary.arn]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.canary_writer_account_id}:root",
        "arn:aws:iam::${var.canary_writer_account_id}:role/github-actions-plan",
        "arn:aws:iam::${var.canary_writer_account_id}:role/github-actions-apply"
      ]
    }
  }

  statement {
    sid    = "AllowCanaryWriterStateObjects"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.state_kms_backend_canary.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.canary_writer_account_id}:root",
        "arn:aws:iam::${var.canary_writer_account_id}:role/github-actions-plan",
        "arn:aws:iam::${var.canary_writer_account_id}:role/github-actions-apply"
      ]
    }
  }

  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.state_kms_backend_canary.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  statement {
    sid    = "DenyMissingEncryptionHeader"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.state_kms_backend_canary.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }

  statement {
    sid    = "DenyIncorrectKmsKeyHeader"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.state_kms_backend_canary.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values = [
        aws_kms_key.state_kms_backend_canary.arn,
        "arn:aws:kms:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${local.state_kms_backend_canary_alias_name}"
      ]
    }
  }

  statement {
    sid    = "DenyMissingKmsKeyHeader"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.state_kms_backend_canary.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = ["true"]
    }
  }
}

output "state_kms_backend_canary_bucket_name" {
  description = "Temporary backend bucket used for the SSE-KMS canary."
  value       = aws_s3_bucket.state_kms_backend_canary.id
}

output "state_kms_backend_canary_kms_alias_arn" {
  description = "Temporary backend KMS alias used for the SSE-KMS canary."
  value       = "arn:aws:kms:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${local.state_kms_backend_canary_alias_name}"
}
