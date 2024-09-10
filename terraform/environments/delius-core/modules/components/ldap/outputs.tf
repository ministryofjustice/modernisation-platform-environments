output "security_group_id" {
  value = aws_security_group.ldap.id
}

output "efs_sg_id" {
  value = module.efs.sg_id
}
