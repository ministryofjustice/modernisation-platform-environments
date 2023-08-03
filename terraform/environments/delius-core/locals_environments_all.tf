locals {
  account_info = {
    business_unit    = var.networking[0].business-unit
    region           = "eu-west-2"
    vpc_id           = data.aws_vpc.shared.id
    application_name = local.application_name
    mp_environment   = local.environment
    id               = data.aws_caller_identity.current.account_id
  }

  platform_vars = {
    environment_management = local.environment_management
  }
  bastion = {
    security_group_id = module.bastion_linux.bastion_security_group
  }
}
