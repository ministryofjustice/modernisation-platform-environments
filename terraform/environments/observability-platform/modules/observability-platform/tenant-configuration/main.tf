module "xray_source" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.xray_enabled
  }

  source = "../../grafana/xray-source"

  name       = each.key
  account_id = var.all_account_ids[each.key]
}

module "cloudwatch_source" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.cloudwatch_enabled
  }

  source = "../../grafana/cloudwatch-source"

  name                         = each.key
  account_id                   = var.all_account_ids[each.key]
  cloudwatch_custom_namespaces = try(each.value.cloudwatch_custom_namespaces, null)
  xray_enabled                 = try(each.value.xray_enabled, false)

  depends_on = [module.xray_source]
}

module "amazon_prometheus_query_source" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.amazon_prometheus_query_enabled
  }

  source = "../../grafana/amazon-prometheus-query-source"

  name                               = each.key
  account_id                         = var.all_account_ids[each.key]
  amazon_prometheus_workspace_region = try(each.value.amazon_prometheus_workspace_region, "eu-west-2")
  amazon_prometheus_workspace_id     = each.value.amazon_prometheus_workspace_id
}

locals {
  flattened_athena_configs = flatten([
    for env_name, env_data in var.aws_accounts : [
      for config_name, config_data in try(env_data.athena_config, {}) : {
        key        = "${env_name}-${config_name}"
        account_id = nonsensitive(var.all_account_ids[env_name])
        database   = config_data.database
        workgroup  = config_data.workgroup
      }
    ] if env_data.athena_enabled == true
  ])
}

module "athena_source" {
  for_each = {
    for config in local.flattened_athena_configs : config.key => config
  }

  source = "../../grafana/athena-source"

  name             = each.key
  account_id       = each.value.account_id
  athena_workgroup = each.value.workgroup
  athena_database  = each.value.database
}

module "prometheus_push" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.prometheus_push_enabled
  }

  source = "../../prometheus/iam-role"

  name       = each.key
  account_id = var.all_account_ids[each.key]
}

module "team" {
  source = "../../grafana/team"

  providers = {
    aws = aws.sso
  }

  name                 = var.name
  identity_centre_team = var.identity_centre_team
  aws_accounts         = var.aws_accounts

  depends_on = [
    module.xray_source,
    module.cloudwatch_source,
    module.amazon_prometheus_query_source,
    module.athena_source
  ]
}
