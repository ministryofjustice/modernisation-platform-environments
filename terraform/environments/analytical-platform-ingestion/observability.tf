module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "9.9.9"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]
  enable_xray                       = true

  tags = local.tags
}

module "analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=4.2.0"

  enable_aws_xray_read_only_access = true

  tags = local.tags
}
