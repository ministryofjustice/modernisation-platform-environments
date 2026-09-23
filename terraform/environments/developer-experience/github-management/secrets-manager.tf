module "github_app_secret" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/github-app"

  kms_key_id = module.kms_key[0].key_arn

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

module "octo_access_entra_id_secret" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name        = "${local.component_name}/entra-id/octo-access"
  description = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/19a2121a-58f2-463a-b986-5c51113a29b7"

  secret_string = jsonencode({
    client_id     = "CHANGEME"
    client_secret = "CHANGEME"
    secret_id     = "CHANGEME"
    tenant_id     = "CHANGEME"
  })
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "2026-10-22" }
  )
}

moved {
  from = module.entra_id_secret[0]
  to   = module.octo_access_entra_id_secret[0]
}

module "octo_access_slack_secret" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name        = "${local.component_name}/slack/octo-access-token"
  description = "https://api.slack.com/apps/A09N2LW1F44"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}
