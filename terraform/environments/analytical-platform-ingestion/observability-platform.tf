module "observability_platform_tenant" {
  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.0.0"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-${local.application_data.accounts[local.environment].observability_platform}"]
  enable_xray                       = true

  tags = local.tags
}