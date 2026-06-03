#### This file can be used to store locals specific to the member account ####
locals {
  current_account_id              = data.aws_caller_identity.current.account_id
  current_account_region          = data.aws_region.current.region
  fabric_tenant_id                = data.aws_secretsmanager_secret_version.fabric_tenant_id.secret_string
  fabric_enterprise_app_object_id = data.aws_secretsmanager_secret_version.fabric_enterprise_app_object_id.secret_string
}
