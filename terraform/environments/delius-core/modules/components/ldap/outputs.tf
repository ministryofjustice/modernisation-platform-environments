output "nlb_dns_name" {
  value = module.nlb.dns_name
}

output "delius_core_ldap_principal_arn" {
  value = aws_ssm_parameter.delius_core_ldap_principal.arn
}

output "delius_core_ldap_bind_password_arn" {
  value = aws_ssm_parameter.delius_core_ldap_bind_password.arn
}

output "security_group_id" {
  value = aws_security_group.ldap.id
}