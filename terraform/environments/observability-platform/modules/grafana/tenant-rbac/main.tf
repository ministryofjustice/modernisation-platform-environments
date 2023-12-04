resource "grafana_team" "this" {
  name = var.name
  team_sync {
    groups = [var.sso_uuid]
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

/* Commenting out as the following code isn't working as expected.
   I've created a ticket with Grafana Labs

data "grafana_data_source" "this" {
  for_each = toset(var.cloudwatch_accounts)

  name = "${each.key}-cloudwatch"
}

resource "grafana_data_source_permission" "this" {
  for_each = toset(var.cloudwatch_accounts)

  datasource_id = data.grafana_data_source.this[each.key].id

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}
*/
