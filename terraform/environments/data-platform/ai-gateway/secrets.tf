module "litellm_license_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/litellm-license"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true
}

module "litellm_salt_key_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/litellm-salt-key"

  secret_string = random_password.litellm_salt_key.result
}

module "litellm_master_key_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/litellm-master-key"

  secret_string = local.litellm_master_key
}

module "litellm_entra_id_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/litellm-entra-id"

  secret_string = jsonencode({
    client_id      = "CHANGEME"
    client_secret  = "CHANGEME"
    tenant_id      = "CHANGEME"
    proxy_admin_id = "CHANGEME"
  })
  ignore_secret_changes = true
}

module "microsoft_foundry_jedi_gateway_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/microsoft-foundry/jedi-gateway"

  secret_string = jsonencode({
    # Legacy API key mechanism
    api_key = "CHANGEME"
    # New OIDC mechanism
    endpoint  = "CHANGEME"
    client_id = "CHANGEME"
    tenant_id = "CHANGEME"
  })
  ignore_secret_changes = true
}

module "google_cloud_ai_gateway_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/google-cloud-platform/moj-gcp-ai-gateway"

  secret_string = jsonencode({
    project_name = "CHANGEME"
    project_id   = "CHANGEME"
  })
  ignore_secret_changes = true
}
