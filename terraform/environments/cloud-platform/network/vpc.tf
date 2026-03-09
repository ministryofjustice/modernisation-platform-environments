module "vpc" {
  version = "6.5.1"
  source  = "terraform-aws-modules/vpc/aws"

  name = local.cp_vpc_name
  cidr = lookup(local.cp_vpc_cidr, local.cluster_environment)
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [
    cidrsubnet(lookup(local.cp_vpc_cidr, local.cluster_environment), 3, 1),
    cidrsubnet(lookup(local.cp_vpc_cidr, local.cluster_environment), 3, 2),
    cidrsubnet(lookup(local.cp_vpc_cidr, local.cluster_environment), 3, 3)
  ]

  public_subnets = [
    cidrsubnet(lookup(local.cp_vpc_cidr, local.cluster_environment), 6, 0),
    cidrsubnet(lookup(local.cp_vpc_cidr, local.cluster_environment), 6, 1),
    cidrsubnet(lookup(local.cp_vpc_cidr, local.cluster_environment), 6, 2)
  ]

  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  public_dedicated_network_acl = true //Creates a dedicated network ACL and attaches to the public subnets

  enable_nat_gateway                  = true
  one_nat_gateway_per_az              = true
  create_multiple_public_route_tables = true

  public_subnet_tags = {
    SubnetType = "Public"
  }

  private_subnet_tags = {
    SubnetType = "Private"
  }

  tags = merge({
    Terraform = "true"
  }, local.tags)
}
