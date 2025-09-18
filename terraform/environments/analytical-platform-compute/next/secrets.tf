module "azure_secrets" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.0"

  name       = "${local.component_name}/azure"
  kms_key_id = data.aws_kms_key.secrets_manager_common.arn

  ignore_secret_changes = true
  secret_string = jsonencode({
    client_id     = "CHANGEME"
    client_secret = "CHANGEME"
    tenant_id     = "CHANGEME"
  })

  # tags = local.tags
  tags = merge(
    local.tags,
    { "secret-expiration" = "29/08/2026" }
  )
}

moved {
  from = module.azure_secret
  to   = module.azure_secrets
}
