module "observability_platform_tenant" {
  //v2.0.0
  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=f69b36c79ba18976d8e500e7cf61cf407158eb61"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]

  tags = local.tags
}
