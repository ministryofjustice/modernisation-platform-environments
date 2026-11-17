module "service_account_credentials" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name        = "${local.component_name}/service-account"
  description = "Service account credentials for GitHub STS"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true
}
