output "nlb_dns_name" {
  value = module.nlb.dns_name
}

output "security_group_id" {
  value = aws_security_group.ldap.id
}