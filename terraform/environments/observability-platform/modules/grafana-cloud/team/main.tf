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
