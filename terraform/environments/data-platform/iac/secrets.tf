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
