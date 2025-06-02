module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]
  enable_xray                       = true

  tags = local.tags
}

module "analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=ccefcbdcecd3c5dfd25474b66ac06a58bd810928" # 2.0.0

  enable_aws_xray_read_only_access = true

  tags = local.tags
}
