module "litellm_license_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "ai-gateway/litellm-license"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true
}

module "litellm_entra_id_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "ai-gateway/litellm-entra-id"

  secret_string = jsonencode({
    client_id      = "CHANGEME"
    client_secret  = "CHANGEME"
    tenant_id      = "CHANGEME"
    proxy_admin_id = "CHANGEME"
  })
  ignore_secret_changes = true
}

module "justiceai_azure_openai_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "ai-gateway/justiceai-azure-openai"

  secret_string = jsonencode({
    api_base = "CHANGEME"
    api_key  = "CHANGEME"
  })
  ignore_secret_changes = true
}

module "azure_openai_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "ai-gateway/azure-openai"

  secret_string = jsonencode({
    api_base = "CHANGEME"
    api_key  = "CHANGEME"
  })
  ignore_secret_changes = true
}
