module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]

  tags = local.tags
}

module "analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=bd09ac68fb3050ddd9992fe4326148aa5d2b1c9b" # 1.1.0

  enable_cloudwatch_read_only_access    = true
  enable_amazon_prometheus_query_access = true
  enable_aws_xray_read_only_access      = true

  additional_policies = {
    managed_prometheus_kms_access = module.managed_prometheus_kms_access_iam_policy.arn
  }

  tags = local.tags
}
