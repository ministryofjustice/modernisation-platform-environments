#------------------------------------------------------------------------------
# Base Instance
#------------------------------------------------------------------------------

module "base_instance" {
  source = "./modules/base_instance"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.accounts[local.environment].base_instances

  name = each.key

  always_on   = each.value.always_on
  ami_name    = each.value.ami_name
  description = each.value.description

  ami_owner           = try(each.value.ami_owner, local.environment_management.account_ids["nomis-test"])
  extra_ingress_rules = try(each.value.extra_ingress_rules, null)
  instance_type       = try(each.value.instance_type, null)

  common_security_group_id  = aws_security_group.base_instance_common.id
  instance_profile_policies = local.ec2_common_managed_policies
  key_name                  = aws_key_pair.ec2-user.key_name

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  subnet_set       = local.subnet_set
  tags             = merge(local.tags, try(each.value.tags, {}))
}

#------------------------------------------------------------------------------
# Security Group for Base Instances
#------------------------------------------------------------------------------

resource "aws_security_group" "base_instance_common" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Security group for base instances"
  name        = "base_instance-common"
  vpc_id      = data.aws_vpc.shared_vpc.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
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
      Name = "base_instance-common"
    }
  )
}
