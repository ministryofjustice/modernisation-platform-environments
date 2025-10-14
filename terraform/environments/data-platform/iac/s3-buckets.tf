data "aws_iam_policy_document" "s3_bucket_policy" {
  # Explicit deny for all principals except allowed ones
  statement {
    sid     = "DenyAllExceptAllowedPrincipals"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::mojdp-${local.environment}-${local.component_name}",
      "arn:aws:s3:::mojdp-${local.environment}-${local.component_name}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      values = [
        module.data_platform_access_iam_role[0].arn,
        "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform-engineer-admin_*",
        "arn:aws:iam::*:role/MemberInfrastructureAccess"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [local.environment_management.account_ids["data-platform-development"]]
    }
  }

  # Allow bucket-level actions for data platform access role
  statement {
    sid    = "AllowDataPlatformAccessBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketVersions"
    ]
    resources = ["arn:aws:s3:::mojdp-${local.environment}-${local.component_name}"]
    principals {
      type        = "AWS"
      identifiers = [module.data_platform_access_iam_role[0].arn]
    }
  }

  # Allow object-level actions for data platform access role
  statement {
    sid    = "AllowDataPlatformAccessObjects"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::mojdp-${local.environment}-${local.component_name}/*"]
    principals {
      type        = "AWS"
      identifiers = [module.data_platform_access_iam_role[0].arn]
    }
  }

  # Allow bucket-level actions for platform engineers
  statement {
    sid    = "AllowDataPlatformEngineersBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketVersions"
    ]
    resources = ["arn:aws:s3:::mojdp-${local.environment}-${local.component_name}"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform-engineer-admin_*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [local.environment_management.account_ids["data-platform-development"]]
    }
  }

  # Allow object-level actions for platform engineers
  statement {
    sid    = "AllowDataPlatformEngineersObjects"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::mojdp-${local.environment}-${local.component_name}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform-engineer-admin_*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [local.environment_management.account_ids["data-platform-development"]]
    }
  }
}

module "s3_bucket" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=c375418373496865e2770ad8aabfaf849d4caee5" # v5.7.0

  bucket = "mojdp-${local.environment}-${local.component_name}"

  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_key[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }
}
