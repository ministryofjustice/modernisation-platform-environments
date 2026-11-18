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
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.secrets_manager.secret_arn]
    }
  }
}