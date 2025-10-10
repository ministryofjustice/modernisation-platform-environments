module "data_platform_access_iam_role" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=dc7a9f3bed20aaaba05d151b0789745070424b3a" # v6.2.1

  path            = "/github-actions/"
  name            = "data-platform-access"
  use_name_prefix = false

  enable_github_oidc = true

  oidc_subjects = ["ministryofjustice/data-platform-access:*"]

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
    S3Access = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["${module.s3_bucket[0].s3_bucket_arn}/data-platform-access/*"]
    }
    SecretsManagerAccess = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.github_token_secret[0].secret_arn]
    }
  }
}
