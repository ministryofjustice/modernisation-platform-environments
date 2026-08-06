##############################################
### Outputs for AD Directory
### (consumed by ad-radius-mfa-config component)
##############################################

output "directory_id" {
  description = "ID of the Managed Microsoft AD directory"
  value       = aws_directory_service_directory.workspaces_ad.id
}
