#### This file can be used to store secrets specific to the member account ####

# Azure Entra ID configuration for WorkSpaces Web authentication
module "azure_entra_config_secret" {
  count = local.create_resources ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.0"

  name        = "azure-entra-workspaces-web-config"
  description = "Azure Entra ID configuration for WorkSpaces Web authentication"

  secret_string = jsonencode({
    tenant_id     = "00000000-0000-0000-0000-000000000000"
    client_id     = "00000000-0000-0000-0000-000000000000"
    client_secret = "PLACEHOLDER_CHANGE_ME"
  })
  # TODO: Define custom cmk for secrets encryption
  ignore_secret_changes = true

  tags = local.tags
}
