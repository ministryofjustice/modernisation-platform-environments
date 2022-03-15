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
  asg_max_size         = each.value.asg_max_size
  asg_desired_capacity = each.value.asg_desired_capacity

  termination_protection = try(each.value.termination_protection, null)

  common_security_group_id    = aws_security_group.weblogic_common.id
  instance_profile_policy_arn = aws_iam_policy.ec2_common_policy.arn
  key_name                    = aws_key_pair.ec2-user.key_name
  load_balancer_listener_arn  = aws_lb_listener.internal.arn

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

#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 weblogic instances
# This is based on the ec2-common-profile but additional permissions may be
# granted as needed
# TODO: delete this once nomis_stack module gone
#------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_weblogic_role" {
  name                 = "ec2-weblogic-role"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    aws_iam_policy.ec2_common_policy.arn
  ]

  tags = merge(
    local.tags,
    {
      Name = "ec2-weblogic-role"
    },
  )
}

# create instance profile from IAM role
resource "aws_iam_instance_profile" "ec2_weblogic_profile" {
  name = "ec2-weblogic-profile"
  role = aws_iam_role.ec2_weblogic_role.name
  path = "/"
}
