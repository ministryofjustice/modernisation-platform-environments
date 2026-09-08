module "iam_role" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=d6e381ccfa95b944149c8b14ba4087e517c57ac7" # v6.8.0

  name            = local.component_name
  use_name_prefix = false

  enable_github_oidc = true

  oidc_wildcard_subjects = ["ministryofjustice@2203574/developer-experience-github-management@1333267581:*"]

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
      resources = ["${module.s3_bucket[0].s3_bucket_arn}/*"]
    }
    SecretsManagerReadAccess = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.github_app_secret[0].secret_arn]
    }
  }
}
