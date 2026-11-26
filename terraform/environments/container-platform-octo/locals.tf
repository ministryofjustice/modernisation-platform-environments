#### This file can be used to store locals specific to the member account ####
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  create_stub_vpc    = contains(keys(local.application_data.accounts), local.environment)
  private_subnets    = local.create_stub_vpc ? cidrsubnets(local.application_data.accounts[local.environment].vpc_cidr, 4, 4, 4) : []
}
