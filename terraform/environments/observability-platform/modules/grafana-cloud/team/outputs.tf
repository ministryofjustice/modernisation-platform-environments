output "folder_uid" {
  description = "The UID of the team's folder"
  value       = grafana_folder.this.uid
}

output "team_id" {
  description = "The ID of the Grafana team"
  value       = grafana_team.this.id
}
