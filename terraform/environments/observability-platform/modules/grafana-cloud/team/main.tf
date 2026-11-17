resource "grafana_team" "this" {
  name = var.name
}

# Requires team sync (GitHub) to be available on the Grafana Cloud plan
resource "grafana_team_external_group" "this" {
  team_id = grafana_team.this.id
  groups  = [var.github_team]
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

# Authoritative: replaces the default Viewer/Editor access so only the team can query its data sources.
# The Terraform service account is Admin and keeps access through its role.
resource "grafana_data_source_permission" "this" {
  for_each = var.data_source_uids

  datasource_uid = each.value

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}
