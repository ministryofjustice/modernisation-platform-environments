module "observability_platform_tenant" {
  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "9.9.8"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]
  
  observability_platform_health_signal_assumer_arns = [
    "arn:aws:iam::${local.environment_management.account_ids["observability-platform-development"]}:role/op-development-health-signals-lambda"
  ]

  enable_health_signal_reader_role = true
}
