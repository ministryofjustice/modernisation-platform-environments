##
# Example terraform file representing Terraform to deploy a component of delius core
# We're only showing an example AWS resources - doesn't really matter what we use
##

# Pre-req - security group
resource "aws_security_group" "sg_ldap" {
  name        = format("%s-%s-sg", var.name, var.ldap_config.name)
  description = var.ldap_config.some_other_attribute
  vpc_id      = var.account_info.vpc_id
  tags        = {}
}

resource "aws_security_group" "sg_db" {
  name        = format("%s-%s-sg", var.name, var.db_config.name)
  description = var.db_config.some_other_attribute
  vpc_id      = var.account_info.vpc_id
  tags        = {}
}

