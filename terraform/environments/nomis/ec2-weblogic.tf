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

  ami_name = each.value.ami_name

  oracle_app_disk_size   = try(each.value.oracle_app_disk_size, null)
  termination_protection = try(each.value.termination_protection, null)

  common_security_group_id   = aws_security_group.database_common.id
  instance_profile_name      = aws_iam_instance_profile.ec2_weblogic_profile.name
  key_name                   = aws_key_pair.ec2-user.key_name
  load_balancer_listener_arn = aws_lb_listener.internal.arn

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  tags             = local.tags
  subnet_set       = local.subnet_set
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 weblogic instances
# This is based on the ec2-common-profile but additional permissions may be
# granted as needed
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
