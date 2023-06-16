##
# Terraform to deploy an instance to test out a base Oracle AMI
##

# Pre-req - security group
resource "aws_security_group" "db_sg" {
  name        = format("%s-db-sg", var.name)
  description = "description"
  vpc_id      = var.account.vpc_id
  tags        = {}
}

