#### This file can be used to store locals specific to the member account ####
locals {
  all_identity_centre_teams = distinct(flatten([
    for tenant_name, tenant_config in local.environment_configuration.tenant_configuration :
    concat(
      lookup(tenant_config, "identity_centre_team", []),
      lookup(tenant_config, "identity_centre_viewer_teams", [])
    ) if tenant_name != "observability-platform"
  ]))

  all_slack_channels = distinct(flatten([
    for tenant in local.environment_configuration.tenant_configuration :
    [for channel in lookup(tenant, "slack_channels", []) : channel]
  ]))

  all_pagerduty_services = distinct(flatten([
    for tenant in local.environment_configuration.tenant_configuration :
    [for service in lookup(tenant, "pagerduty_services", []) : service]
  ]))

  all_aws_accounts = distinct(flatten([
    for tenant_name, tenant_config in local.environment_configuration.tenant_configuration : [
      for account_name, _ in lookup(tenant_config, "aws_accounts", {}) : account_name
    ]
  ]))
}
