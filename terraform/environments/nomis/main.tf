#------------------------------------------------------------------------------
# NOMIS stack
#------------------------------------------------------------------------------

module "nomis_stack" {
  source = "./modules/nomis_stack"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.application_data.accounts[local.environment].stacks

  stack_name                        = each.key
  database_ami_name                 = each.value.database_ami_name
  weblogic_ami_name                 = each.value.weblogic_ami_name
  database_extra_ingress_rules      = each.value.database_extra_ingress_rules
  weblogic_common_security_group_id = aws_security_group.weblogic_common.id

  bastion_security_group     = module.bastion_linux.bastion_security_group
  instance_profile_id        = aws_iam_instance_profile.ec2_common_profile.id
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

data "aws_subnet" "private_az_a" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

# Security Groups
resource "aws_security_group" "weblogic_common" {
  description = "Configure weblogic access - ingress should be only from Bastion"
  name        = "weblogic-server-${local.application_name}"
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
      Name = "weblogic-server-${local.application_name}"
    }
  )
}