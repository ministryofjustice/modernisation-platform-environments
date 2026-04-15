output "folder_id" {
  description = "The Grafana folder ID for this team"
  value       = module.team.folder_id
}

output "folder_uid" {
  description = "The Grafana folder UID for this team"
  value       = module.team.folder_uid
}
