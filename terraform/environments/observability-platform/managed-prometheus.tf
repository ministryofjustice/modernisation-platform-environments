locals {
  all_prometheus_accounts = distinct(flatten([
    for tenant_name, tenant_config in local.environment_configuration.observability_platform_configuration : [
      lookup(tenant_config, "prometheus_accounts", [])
    ]
  ]))
}

module "managed_prometheus" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/managed-service-prometheus/aws"
  version = "~> 2.0"

  workspace_alias = local.application_name

  tags = local.tags
}

/* Prometheus Roles */
module "prometheus_roles" {
  for_each = {
    for account in local.all_prometheus_accounts : account => {
      account_id = account
    }
  }

  source = "./modules/prometheus/iam-role"

  name                     = each.key
  account_id               = local.environment_management.account_ids[each.key]
  prometheus_workspace_arn = module.managed_prometheus.workspace_arn
}
