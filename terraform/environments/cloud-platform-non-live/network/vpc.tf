module "vpc" {
  version = "6.5.1"  
  source = "terraform-aws-modules/vpc/aws"

  name = local.cp_vpc_name
  cidr = lookup(local.cp_vpc_cidr, terraform.workspace)
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [
    cidrsubnet(lookup(local.cp_vpc_cidr, terraform.workspace), 3, 1),
    cidrsubnet(lookup(local.cp_vpc_cidr, terraform.workspace), 3, 2),
    cidrsubnet(lookup(local.cp_vpc_cidr, terraform.workspace), 3, 3)
  ]

  public_subnets = [
    cidrsubnet(lookup(local.cp_vpc_cidr, terraform.workspace), 6, 0),
    cidrsubnet(lookup(local.cp_vpc_cidr, terraform.workspace), 6, 1),
    cidrsubnet(lookup(local.cp_vpc_cidr, terraform.workspace), 6, 2)
  ]

  enable_nat_gateway = true
  one_nat_gateway_per_az = true
  enable_dns_hostnames = true
  create_multiple_public_route_tables = true

  tags = merge({
    Terraform = "true"
  }, local.tags)  
}
