output "folder_uid" {
  description = "The UID of the team's folder"
  value       = grafana_folder.this.uid
}

output "folder_id" {
  description = "The ID of the team's folder"
  value       = grafana_folder.this.id
}

output "team_id" {
  description = "The ID of the team"
  value       = grafana_team.this.id
}
