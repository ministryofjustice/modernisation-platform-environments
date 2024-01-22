resource "grafana_team" "this" {
  name = var.name
  team_sync {
    groups = [var.identity_centre_team]
  }
}

resource "grafana_folder" "this" {
  title = var.name
}

resource "grafana_folder_permission" "this" {
  folder_uid = grafana_folder.this.uid
  permissions {
    team_id    = grafana_team.this.id
    permission = "Admin"
  }
}

data "grafana_data_source" "cloudwatch" {
  for_each = var.aws_accounts

  name = "${each.key}-cloudwatch"
}

resource "grafana_data_source_permission" "cloudwatch" {
  for_each = var.aws_accounts

  datasource_id = data.grafana_data_source.cloudwatch[each.key].id

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}

data "grafana_data_source" "xray" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.xray_enabled
  }

  name = "${each.key}-xray"
}

resource "grafana_data_source_permission" "xray" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.xray_enabled
  }

  datasource_id = data.grafana_data_source.xray[each.key].id

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}
