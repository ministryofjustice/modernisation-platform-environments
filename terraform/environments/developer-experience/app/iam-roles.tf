module "cloud_platform_eso_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=82afc6ce4a44b5e97ad00c10d7909c887078f07d" # v6.11.0

  name            = "${local.component_name}-cloud-platform-eso"
  use_name_prefix = false

  oidc_providers = {
    cloud_platform = {
      provider_arn               = data.aws_iam_openid_connect_provider.cloud_platform.arn
      namespace_service_accounts = ["${local.environment_configuration.cloud_platform_namespace}:${local.component_name}-eso"]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    KMSAccess = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.kms_key.key_arn]
    }
    SecretsManagerAccess = {
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = [
        module.github_app_secret.secret_arn,
        module.entra_app_secret.secret_arn,
        module.notify_secret.secret_arn,
        module.sentry_secret.secret_arn
      ]
    }
  }
}

module "github_actions_iam_role" {
  count = local.is-development ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=ba3fd6ded6911e0454092147fe3704171cc05e00" # v6.8.1

  name            = "developer-experience-app-github-actions"
  use_name_prefix = false

  enable_github_oidc     = true
  oidc_wildcard_subjects = ["ministryofjustice@2203574/developer-experience-app@1324040641:*"]

  create_inline_policy = true
  inline_policy_permissions = {
    SecretsManagerReadAccess = {
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = [
        module.github_app_secret.secret_arn,
        module.entra_app_secret.secret_arn,
        module.notify_secret.secret_arn,
      ]
    }
    SecretsManagerListAccess = {
      effect    = "Allow"
      actions   = ["secretsmanager:ListSecrets"]
      resources = ["*"]
    }
    KMSDecryptAccess = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.kms_key.key_arn]
    }
  }
}
