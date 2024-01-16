output "ldap_efs_location" {
  value = aws_efs_file_system.ldap.arn
}

output "efs_file_system_id" {
  description = "id that identifies the file system"
  value       = aws_efs_file_system.ldap.id
}

output "ldap_security_group_id" {
  value = aws_security_group.ldap_efs.id
}

output "ldap_efs_security_group_arn" {
  value = aws_security_group.ldap_efs.arn
}