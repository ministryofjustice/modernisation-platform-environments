#### This file can be used to store locals specific to the member account ####
locals {
  env_account_id     = local.environment_management.account_ids[terraform.workspace]
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets    = cidrsubnets(local.application_data.accounts[local.environment].vpc_cidr, 4, 4, 4)
}
