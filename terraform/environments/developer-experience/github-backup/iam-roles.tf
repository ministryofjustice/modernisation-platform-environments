module "github_backup_role" {
  count = local.is_production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=ba3fd6ded6911e0454092147fe3704171cc05e00" # v6.8.1

  name            = local.component_name
  use_name_prefix = false

  enable_github_oidc     = true
  oidc_wildcard_subjects = ["ministryofjustice@2203574/developer-experience-github-management@1333267581:*"]

  create_inline_policy = true
  inline_policy_permissions = {
    github_backup_destination_read = {
      sid       = "GitHubBackupDestinationRead"
      effect    = "Allow"
      actions   = ["ssm:GetParameter"]
      resources = [aws_ssm_parameter.github_backup_destination[0].arn]
    }
    github_backup_upload = {
      sid    = "GitHubBackupUpload"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:AbortMultipartUpload"
      ]
      resources = ["${module.github_backup_bucket[0].s3_bucket_arn}/*"]
    }
    github_backup_encryption = {
      sid    = "GitHubBackupEncryption"
      effect = "Allow"
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      resources = [module.github_backup_key[0].key_arn]
    }
    github_app_secret_read = {
      sid       = "GitHubAppSecretRead"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [data.aws_secretsmanager_secret.github_app[0].arn]
    }
    github_app_secret_decrypt = {
      sid       = "GitHubAppSecretDecrypt"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [data.aws_kms_key.github_management[0].arn]
    }
  }
}
