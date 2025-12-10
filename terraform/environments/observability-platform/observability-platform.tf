module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  observability_platform_account_id = data.aws_caller_identity.current.account_id
  enable_xray                       = true

  tags = local.tags
}




