module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]
  enable_xray                       = true

  tags = local.tags
}

module "analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=bd09ac68fb3050ddd9992fe4326148aa5d2b1c9b" # 1.1.0

  tags = local.tags
}
