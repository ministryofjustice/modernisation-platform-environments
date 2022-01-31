#------------------------------------------------------------------------------
# NOMIS stack
#------------------------------------------------------------------------------

module "nomis_stack" {
  source = "./modules/nomis_stack"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.application_data.accounts[local.environment].stacks

  stack_name                   = each.key
  database_ami_name            = each.value.database_ami_name
  database_extra_ingress_rules = each.value.database_extra_ingress_rules
  weblogic_ami_name            = each.value.weblogic_ami_name

  database_common_security_group_id = aws_security_group.database_common.id
  weblogic_common_security_group_id = aws_security_group.weblogic_common.id

  instance_profile_name      = aws_iam_instance_profile.ec2_common_profile.name
  instance_profile_role_name = aws_iam_role.ec2_database_role.name
  key_name                   = aws_key_pair.ec2-user.key_name
  load_balancer_listener_arn = aws_lb_listener.internal.arn

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  region           = local.region
  tags             = local.tags
  subnet_set       = local.subnet_set
}

#------------------------------------------------------------------------------
# Common Security Group for Weblogic Instances
#------------------------------------------------------------------------------

resource "aws_security_group" "weblogic_common" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Common security group for weblogic instances"
  name        = "weblogic-common"
  vpc_id      = local.vpc_id

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description     = "access from Windows Jumpserver (admin console)"
    from_port       = "7001"
    to_port         = "7001"
    protocol        = "TCP"
    security_groups = [aws_security_group.jumpserver-windows.id]
  }

  ingress {
    description     = "access from Windows Jumpserver"
    from_port       = "80"
    to_port         = "80"
    protocol        = "TCP"
    security_groups = [aws_security_group.jumpserver-windows.id]
  }

  ingress {
    description     = "access from Windows Jumpserver (forms/reports)"
    from_port       = "7777"
    to_port         = "7777"
    protocol        = "TCP"
    security_groups = [aws_security_group.jumpserver-windows.id, aws_security_group.internal_elb.id]
  }

  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "weblogic-commmon"
    }
  )
}

#------------------------------------------------------------------------------
# Common Security Group for Database Instances
#------------------------------------------------------------------------------

resource "aws_security_group" "database_common" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Common security group for database instances"
  name        = "database-common"
  vpc_id      = data.aws_vpc.shared_vpc.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description = "External access to database port"
    from_port   = "1521"
    to_port     = "1521"
    protocol    = "TCP"
    cidr_blocks = [
      for cidr in local.application_data.accounts[local.environment].database_external_access_cidr : cidr
    ]
  }

  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "database-common"
    }
  )
}