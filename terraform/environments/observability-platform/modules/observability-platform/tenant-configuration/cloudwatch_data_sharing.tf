locals {
  shared_cloudwatch_permissions = flatten([
    for account_name, account in var.aws_accounts : [
      for team_name in try(account.cloudwatch_shared_with_teams, []) : {
        key             = "${account_name}:${team_name}"
        datasource_name = "${account_name}-cloudwatch"
        team_name       = team_name
      }
    ] if try(account.cloudwatch_enabled, false)
  ])
}

data "grafana_data_source" "shared_cloudwatch" {
  for_each = {
    for item in local.shared_cloudwatch_permissions : item.key => item
  }

  name = each.value.datasource_name
}

data "grafana_team" "shared_cloudwatch" {
  for_each = toset([
    for item in local.shared_cloudwatch_permissions : item.team_name
  ])

  name = each.value
}

resource "grafana_data_source_permission_item" "shared_cloudwatch" {
  for_each = {
    for item in local.shared_cloudwatch_permissions : item.key => item
  }

  datasource_uid = data.grafana_data_source.shared_cloudwatch[each.key].uid

  team       = data.grafana_team.shared_cloudwatch[each.value.team_name].id
  permission = "Query"
}
