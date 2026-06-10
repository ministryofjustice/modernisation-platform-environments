#### This file can be used to store locals specific to the member account ####
locals {
  current_account_id              = data.aws_caller_identity.current.account_id
  current_account_region          = data.aws_region.current.region
  fabric_tenant_id                = local.is-development ? data.aws_secretsmanager_secret_version.fabric_tenant_id[0].secret_string : null
  fabric_enterprise_app_object_id = local.is-development ? data.aws_secretsmanager_secret_version.fabric_enterprise_app_object_id[0].secret_string : null
}
