module "cloud_platform_live_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name = "cloud-platform/live"

  secret_string = jsonencode({
    ca_certificate   = "CHANGEME"
    cluster_endpoint = "CHANGEME"
    oidc_provider    = "CHANGEME"
  })
  ignore_secret_changes = true
}
