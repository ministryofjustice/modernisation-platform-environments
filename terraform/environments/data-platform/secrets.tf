module "cloud_platform_live_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=82029345dea22bc49989a6f46c5d8d8e555b84c9" # v2.0.0

  name = "cloud-platform/live"

  secret_string = jsonencode({
    ca_certificate   = "CHANGEME"
    cluster_endpoint = "CHANGEME"
    oidc_provider    = "CHANGEME"
  })
  ignore_secret_changes = true
}
