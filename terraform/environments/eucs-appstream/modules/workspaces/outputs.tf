output "directory_id" {
  value = aws_directory_service_directory.ad_connector.id
}

output "workspaces_directory_id" {
  value = aws_workspaces_directory.this.id
}

output "registration_code" {
  value = aws_workspaces_directory.this.registration_code
}

output "security_group_id" {
  value = aws_security_group.workspaces.id
}

output "ip_group_id" {
  value = aws_workspaces_ip_group.this.id
}
