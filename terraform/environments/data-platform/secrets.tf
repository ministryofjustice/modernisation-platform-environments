# Shared Cloud Platform live cluster connection details. Created in development
# and production because components in those accounts (e.g. monitoring) read this
# secret cross-configuration to configure their kubernetes/helm providers.
module "cloud_platform_live_secret" {
  count = contains(["data-platform-development", "data-platform-production"], terraform.workspace) ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=82029345dea22bc49989a6f46c5d8d8e555b84c9" # v2.0.1

  name = "cloud-platform/live"

  secret_string = jsonencode({
    ca_certificate   = "CHANGEME"
    cluster_endpoint = "CHANGEME"
    oidc_provider    = "CHANGEME"
  })
  ignore_secret_changes = true
}
