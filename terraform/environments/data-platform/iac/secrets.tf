module "github_token_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name = "github/token"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true
}
