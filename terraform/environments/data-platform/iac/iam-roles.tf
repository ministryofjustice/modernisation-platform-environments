module "data_platform_access_iam_role" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=7279fc444aed7e36c60438b46972e1611e48984c" # v6.2.3

  path            = "/github-actions/"
  name            = "data-platform-access"
  use_name_prefix = false

  enable_github_oidc = true

  oidc_wildcard_subjects = ["ministryofjustice/data-platform-access:*"]

  create_inline_policy = true
  inline_policy_permissions = {
    KMSAccess = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = [module.kms_key[0].key_arn]
    }
    S3BucketAccess = {
      effect = "Allow"
      actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketVersions"
      ]
      resources = [module.s3_bucket[0].s3_bucket_arn]
    }
    S3ObjectAccess = {
      effect = "Allow"
      actions = [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["${module.s3_bucket[0].s3_bucket_arn}/data-platform-access/*"]
    }
    SecretsManagerReadAccess = {
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = [
        module.entra_secret[0].secret_arn,
        module.github_app_secret[0].secret_arn,
        module.pagerduty_api_key_secret[0].secret_arn,
        module.slack_token_secret[0].secret_arn
      ]
    }
    SecretsManagerWriteAccess = {
      effect  = "Allow"
      actions = [
        "secretsmanager:CreateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecret"
      ]
      resources = [
        /* Secrets Managed by Data Platform Access */
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:pagerduty/*" # PagerDuty
      ]
    }
  }
}

module "octo_access_iam_role" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=7279fc444aed7e36c60438b46972e1611e48984c" # v6.2.3

  path            = "/github-actions/"
  name            = "octo-access"
  use_name_prefix = false

  enable_github_oidc = true

  oidc_wildcard_subjects = ["ministryofjustice/octo-access:*"]

  create_inline_policy = true
  inline_policy_permissions = {
    KMSAccess = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = [module.octo_kms_key[0].key_arn]
    }
    S3BucketAccess = {
      effect = "Allow"
      actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketVersions"
      ]
      resources = [module.octo_s3_bucket[0].s3_bucket_arn]
    }
    S3ObjectAccess = {
      effect = "Allow"
      actions = [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["${module.octo_s3_bucket[0].s3_bucket_arn}/octo-access/*"]
    }
    SecretsManagerAccess = {
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = [
        module.octo_entra_secret[0].secret_arn,
        module.octo_github_app_secret[0].secret_arn,
        module.octo_slack_token_secret[0].secret_arn
      ]
    }
  }
}
