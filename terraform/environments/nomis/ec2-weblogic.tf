#------------------------------------------------------------------------------
# Weblogic
#------------------------------------------------------------------------------

module "weblogic" {
  source = "./modules/weblogic"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.application_data.accounts[local.environment].weblogics

  name = each.key

  ami_name             = each.value.ami_name
  asg_max_size         = try(each.value.asg_max_size, null)
  asg_min_size         = try(each.value.asg_min_size, null)
  asg_desired_capacity = try(each.value.asg_desired_capacity, null)

  termination_protection = try(each.value.termination_protection, null)

  common_security_group_id   = aws_security_group.weblogic_common.id
  instance_profile_policies  = local.ec2_common_managed_policies
  key_name                   = aws_key_pair.ec2-user.key_name
  load_balancer_listener_arn = aws_lb_listener.internal.arn

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
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
    description = "access from Windows Jumpserver and loadbalancer (forms/reports)"
    from_port   = "7777"
    to_port     = "7777"
    protocol    = "TCP"
    security_groups = [
      aws_security_group.jumpserver-windows.id,
      aws_security_group.internal_elb.id
    ]
  }

  ingress {
  description = "access from Cloud Platform Prometheus server"
  from_port   = "9100"
  to_port     = "9100"
  protocol    = "TCP"
  cidr_blocks = [local.application_data.accounts[local.environment].database_external_access_cidr.cloud_platform]
}

  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "weblogic-commmon"
    }
  )
}
