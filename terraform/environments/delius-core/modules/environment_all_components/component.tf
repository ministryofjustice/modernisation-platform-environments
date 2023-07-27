##
# Example terraform file representing Terraform to deploy a component of delius core
# We're only showing an example AWS resources - doesn't really matter what we use
##

resource "aws_security_group" "sg_db" {
  name        = format("%s-%s-sg", var.env_name, var.db_config.name)
  vpc_id      = var.account_info.vpc_id
  tags        = {}
}

