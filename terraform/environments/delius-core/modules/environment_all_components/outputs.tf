##
# Output variables here
##

output "ldap_efs_location" {
  value = module.efs.ldap_efs_location
}


output "acm_domains" {
  value = aws_acm_certificate.external
}