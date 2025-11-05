module "cloud_platform_live_namespace_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name = "cloud-platform/live/${local.component_name}"

  secret_string = jsonencode({
    namespace = "CHANGEME"
    token     = "CHANGEME"
  })
  ignore_secret_changes = true
}

module "litellm_license_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name = "litellm/license"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true
}

module "litellm_entra_id_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name = "litellm/entra-id"

  secret_string = jsonencode({
    client_id      = "CHANGEME"
    client_secret  = "CHANGEME"
    tenant_id      = "CHANGEME"
    proxy_admin_id = "CHANGEME"
  })
  ignore_secret_changes = true
}

module "justiceai_azure_openai_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f7fef2d8f63f1595c3e2b0ee14a6810dc7bdb9af" # v2.0.0

  name = "justice-ai/azure-openai"

  secret_string = jsonencode({
    api_base = "CHANGEME"
    api_key  = "CHANGEME"

  })
  ignore_secret_changes = true
}
