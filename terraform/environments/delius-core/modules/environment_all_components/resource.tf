##
# Terraform to deploy an instance to test out a base Oracle AMI
##

# Pre-req - security group
resource "aws_security_group" "sg_ldap" {
  name        = format("%s-%s-sg", var.name, var.ldap_config.name)
  description = var.ldap_config.some_other_attribute
  vpc_id      = var.account.vpc_id
  tags        = {}
}

resource "aws_security_group" "sg_db" {
  name        = format("%s-%s-sg", var.name, var.db_config.name)
  description = var.db_config.some_other_attribute
  vpc_id      = var.account.vpc_id
  tags        = {}
}

