output "folder_uid" {
  description = "The UID of the team's folder"
  value       = grafana_folder.this.uid
}

output "team_id" {
  description = "The ID of the Grafana team"
  value       = grafana_team.this.id
}

output "team_uid" {
  description = "The UID of the Grafana team, as used by data source label-based access control (LBAC) rules"
  value       = grafana_team.this.team_uid
}
