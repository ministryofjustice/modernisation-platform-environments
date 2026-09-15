locals {
  vpc_availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr               = "10.0.0.0/23"
  vpc_subnets            = [for cidr_block in cidrsubnets(local.vpc_cidr, 2, 2, 2, 2) : cidrsubnets(cidr_block, 2, 2, 2)]
  vpc_subnets_public     = local.vpc_subnets[0]
  vpc_subnets_private    = local.vpc_subnets[1]
}