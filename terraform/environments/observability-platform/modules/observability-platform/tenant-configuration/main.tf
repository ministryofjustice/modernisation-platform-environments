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

  name         = each.key
  account_id   = var.environment_management.account_ids[each.key]
  xray_enabled = each.value.xray_enabled

  depends_on = [module.xray_source]
}
