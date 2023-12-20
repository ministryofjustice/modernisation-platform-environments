module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "0.1.0"

  observability_platform_account_id = local.environment_configuration.observability_platform_account_id
}
