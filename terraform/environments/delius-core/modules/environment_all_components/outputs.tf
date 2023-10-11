##
# Output variables here
##

output "ldap_efs_location" {
  value = aws_efs_file_system.ldap.arn
}

output "ldap_efs_security_group_id" {
  value = aws_security_group.ldap.id
}