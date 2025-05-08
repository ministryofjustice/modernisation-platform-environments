module "tenant_configuration" {
  for_each = local.environment_configuration.tenant_configuration

  source = "./modules/observability-platform/tenant-configuration"

  providers = {
    aws.sso = aws.sso-readonly
  }

  environment_management = local.environment_management
  name                   = each.key
  identity_centre_team   = each.value.identity_centre_team
  aws_accounts           = each.value.aws_accounts
  all_account_ids        = local.all_account_ids
}
