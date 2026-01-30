module "observability_platform_tenant" {
  source = "ministryofjustice/observability-platform-tenant/aws"
  version = "2.0.0"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]

  tags = local.tags
}
