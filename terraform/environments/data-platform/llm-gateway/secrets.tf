module "cloud_platform_live_namespace_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "cloud-platform/live/${local.component_name}"

  secret_string = jsonencode({
    namespace = "CHANGEME"
    token     = "CHANGEME"
  })
  ignore_secret_changes = true
}

module "litellm_license_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "litellm/license"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true
}

module "litellm_entra_id_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

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

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "justice-ai/azure-openai"

  secret_string = jsonencode({
    api_base = "CHANGEME"
    api_key  = "CHANGEME"

  })
  ignore_secret_changes = true
}

module "litellm_keys_secret" {
  for_each = terraform.workspace == "data-platform-development" ? litellm_key.keys : {}

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "litellm/keys/${each.value.key_alias}"

  secret_string = each.value.id
}

