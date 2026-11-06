output "radius_configuration_complete" {
  description = "Indicates if RADIUS configuration is applied to the AD directory"
  value       = try(aws_directory_service_radius_settings.workspaces_ad_radius.id != null, false)
}

output "radius_directory_id" {
  description = "ID of the AD directory with RADIUS configured"
  value       = aws_directory_service_radius_settings.workspaces_ad_radius.directory_id
}
