module "cloud_platform_service_account_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name       = "${local.component_name}/cloud-platform-service-account"
  kms_key_id = module.kms_key.key_arn

  secret_string = "CHANGEME"

  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}

module "github_app_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name       = "${local.component_name}/github-app"
  kms_key_id = module.kms_key.key_arn

  secret_string = jsonencode({
    app_id          = "CHANGEME"
    client_id       = "CHANGEME"
    installation_id = "CHANGEME"
    private_key     = "CHANGEME"
  })

  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}

resource "random_password" "webhook_signing_secret" {
  count = local.is-production ? 1 : 0

  length  = 64
  special = false
}

module "webhook_signing_secret" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name        = "${local.component_name}/webhook-signing-secret"
  description = "GitHub App webhook signing secret"
  kms_key_id  = module.kms_key.key_arn

  secret_string = random_password.webhook_signing_secret[0].result
}
