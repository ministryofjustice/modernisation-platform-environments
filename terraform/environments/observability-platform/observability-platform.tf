module "observability_platform_tenant" {
  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.0.0"

  observability_platform_account_id = data.aws_caller_identity.current.account_id
  enable_xray                       = true

  tags = local.tags
}
