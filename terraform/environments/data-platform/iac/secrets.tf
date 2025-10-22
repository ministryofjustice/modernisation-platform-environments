module "entra_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name        = "entra/data-platform-access"
  description = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/fecb63c0-54ac-47a8-98d7-6490aa61312e"

  secret_string = jsonencode({
    client_id     = "CHANGEME"
    client_secret = "CHANGEME"
    secret_id     = "CHANGEME"
    tenant_id     = "CHANGEME"
  })
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "2026-04-12" }
  )
}

module "github_token_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name        = "github/data-platform-github-access-token"
  description = "Token (data-platform-github-access) owned by moj-data-platform-robot"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "2026-09-25" }
  )
}

module "slack_token_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name        = "slack/data-platform-access-token"
  description = "https://api.slack.com/apps/A09LGS1RL68"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}

module "octo_entra_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name        = "entra/octo-access"
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

module "octo_slack_token_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name        = "slack/octo-access-token"
  description = "https://api.slack.com/apps/A09N2LW1F44"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}
