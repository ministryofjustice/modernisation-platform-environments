#### This file can be used to store locals specific to the member account ####
locals {
  all_identity_centre_teams = distinct(flatten([
    for tenant_name, tenant_config in local.environment_configuration.tenant_configuration :
    lookup(tenant_config, "identity_centre_team", []) if tenant_name != "observability-platform"
  ]))

  all_aws_accounts = flatten([
    for tenant_name, tenant_config in local.environment_configuration.tenant_configuration : [
      for account_name, _ in lookup(tenant_config, "aws_accounts", {}) : account_name
    ]
  ])
}
