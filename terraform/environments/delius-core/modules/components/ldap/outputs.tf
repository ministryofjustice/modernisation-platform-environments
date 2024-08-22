output "nlb_dns_name" {
  value = module.nlb.dns_name
}

output "delius_core_ldap_principal_arn" {
  value = aws_ssm_parameter.delius_core_ldap_principal.arn
}

output "delius_core_ldap_bind_password_arn" {
  value = aws_ssm_parameter.delius_core_ldap_bind_password.arn
}

output "delius_core_ldap_seed_uri_arn" {
  value = aws_ssm_parameter.delius_core_ldap_seed_uri.arn
}

output "delius_core_ldap_rbac_version_arn" {
  value = aws_ssm_parameter.delius_core_ldap_rbac_version.arn
}

output "security_group_id" {
  value = aws_security_group.ldap.id
}
