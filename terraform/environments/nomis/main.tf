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
  database_extra_ingress_rules = try(each.value.database_extra_ingress_rules, [])
  weblogic_ami_name            = each.value.weblogic_ami_name
  weblogic_ami_owner           = each.value.weblogic_ami_owner

  database_common_security_group_id = aws_security_group.database_common.id
  weblogic_common_security_group_id = aws_security_group.weblogic_common.id

  instance_profile_name          = aws_iam_instance_profile.ec2_common_profile.name
  instance_profile_db_name       = aws_iam_instance_profile.ec2_database_profile.name
  instance_profile_weblogic_name = aws_iam_instance_profile.ec2_weblogic_profile.name
  key_name                       = aws_key_pair.ec2-user.key_name
  load_balancer_listener_arn     = aws_lb_listener.internal.arn

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  region           = local.region
  tags             = local.tags
  subnet_set       = local.subnet_set
}