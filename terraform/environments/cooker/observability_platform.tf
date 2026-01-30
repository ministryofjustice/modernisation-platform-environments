module "observability_platform_tenant" {
  source = "ministryofjustice/observability-platform-tenant/aws"
  version = "9.9.9"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]

  tags = local.tags
}
