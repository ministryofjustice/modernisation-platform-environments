#### This file can be used to store locals specific to the member account ####
locals {
  current_account_id     = data.aws_caller_identity.current.account_id
  current_account_region = data.aws_region.current.region

  fabric_oidc_enabled_environments = ["development"]

  fabric_oidc_enabled = contains(
    local.fabric_oidc_enabled_environments,
    local.environment
  )

  fabric_tenant_id = (
    local.fabric_oidc_enabled
    ? trimspace(data.aws_secretsmanager_secret_version.fabric_tenant_id[0].secret_string)
    : null
  )

  fabric_enterprise_app_object_id = (
    local.fabric_oidc_enabled
    ? trimspace(data.aws_secretsmanager_secret_version.fabric_enterprise_app_object_id[0].secret_string)
    : null
  )
}
