#### This file can be used to store locals specific to the member account ####
locals {
  all_sso_uuids = distinct(flatten([
    for tenant_name, tenant_config in local.environment_configuration.observability_platform_configuration :
    lookup(tenant_config, "sso_uuid", []) if tenant_name != "observability-platform"
  ]))

  all_cloudwatch_accounts = distinct(flatten([
    for tenant_name, tenant_config in local.environment_configuration.observability_platform_configuration : [
      lookup(tenant_config, "cloudwatch_accounts", [])
    ]
  ]))

  all_prometheus_accounts = distinct(flatten([
    for tenant_name, tenant_config in local.environment_configuration.observability_platform_configuration : [
      lookup(tenant_config, "prometheus_accounts", [])
    ]
  ]))
}
