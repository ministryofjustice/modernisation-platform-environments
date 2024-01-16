##
# Output variables here
##

output "ldap_efs_location" {
  value = module.efs.ldap_efs_location
}

output "ldap_efs_security_group_id" {
  value = aws_security_group.ldap.id
}

output "acm_domains" {
  value = aws_acm_certificate.external
}