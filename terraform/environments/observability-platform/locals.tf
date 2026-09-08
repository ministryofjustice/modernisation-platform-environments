#### This file can be used to store locals specific to the member account ####
locals {
  all_identity_centre_teams = distinct(flatten([
    for tenant_name, tenant_config in local.environment_configuration.tenant_configuration :
    lookup(tenant_config, "identity_centre_team", []) if tenant_name != "observability-platform"
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
  all_account_ids = merge(
    local.environment_management.account_ids,
    local.nonmp_account_ids
  )

  securityhub_event_bus_name = "securityhub-central"

  ccms_account_ids = [
    for account_name, _ in lookup(local.environment_configuration.tenant_configuration["ccms"], "aws_accounts", {}) :
    local.all_account_ids[account_name]
    if contains(keys(local.all_account_ids), account_name)
  ]

  securityhub_source_account_ids = sort(distinct(concat(
    [
      for account_name, account_id in local.environment_management.account_ids : account_id
      if can(regex("^core-", account_name))
    ],
    local.ccms_account_ids
  )))

  securityhub_account_name_map = {
    for account_name, account_id in local.all_account_ids :
    account_id => account_name if contains(local.securityhub_source_account_ids, account_id)
  }
}
