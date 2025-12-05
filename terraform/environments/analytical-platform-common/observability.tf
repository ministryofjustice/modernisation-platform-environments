module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "2.0.0"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]

  tags = local.tags
}

module "analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=4b9c9013bff6035e8e3b77a00d124e62bbb4de56" # 4.2.0

  enable_aws_xray_read_only_access = true

  tags = local.tags
}
