module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  # source  = "ministryofjustice/observability-platform-tenant/aws"
  # version = "1.0.1"

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=feat%2Fsupport-additional-polices"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-${local.environment_configuration.observability_platform}"]
  enable_prometheus                 = true
  enable_xray                       = true
  additional_policies = {
    managed_prometheus_kms_access = module.managed_prometheus_kms_access_iam_policy.arn
  }

  tags = local.tags
}
