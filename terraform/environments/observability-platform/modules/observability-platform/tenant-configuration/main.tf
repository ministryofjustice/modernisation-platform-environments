module "xray_source" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.xray_enabled
  }

  source = "../../grafana/xray-source"

  name       = each.key
  account_id = var.environment_management.account_ids[each.key]
}

module "cloudwatch_source" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.cloudwatch_enabled
  }

  source = "../../grafana/cloudwatch-source"

  name                         = each.key
  account_id                   = var.environment_management.account_ids[each.key]
  cloudwatch_custom_namespaces = try(each.value.cloudwatch_custom_namespaces, null)
  xray_enabled                 = try(each.value.xray_enabled, false)

  depends_on = [module.xray_source]
}
