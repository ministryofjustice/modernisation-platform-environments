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
