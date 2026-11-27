module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "3.0.0"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]
  enable_prometheus                 = true
  enable_xray                       = true
  additional_policies = {
    managed_prometheus_kms_access = local.environment_configuration.managed_prometheus_kms_access_iam_policy_arn
  }

  tags = local.tags
}

module "analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=42f7caa1dd0809715721e632fb8b4e26a0559e99" # 4.2.0

  enable_amazon_prometheus_query_access = true
  enable_aws_xray_read_only_access      = true

  additional_policies = {
    managed_prometheus_kms_access = local.environment_configuration.managed_prometheus_kms_access_iam_policy_arn
  }

  tags = local.tags
}
