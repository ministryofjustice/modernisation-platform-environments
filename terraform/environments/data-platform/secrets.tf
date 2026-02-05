module "cloud_platform_live_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "cloud-platform/live"

  secret_string = jsonencode({
    ca_certificate   = "CHANGEME"
    cluster_endpoint = "CHANGEME"
    oidc_provider    = "CHANGEME"
  })
  ignore_secret_changes = true
}
