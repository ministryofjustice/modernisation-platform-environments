module "observability_platform_tenant" {
  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "9.9.9"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]
  tags = local.tags

  enable_health_signal_reader_role = true

  observability_platform_health_signal_assumer_arns = [
    "arn:aws:iam::${local.environment_management.account_ids["observability-platform-development"]}:role/op-production-health-signals-lambda"
  ]
}
