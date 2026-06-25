module "cluster_vpc" {
  version = "6.5.1"
  source  = "terraform-aws-modules/vpc/aws"

  name = local.cp_vpc_name
  cidr = contains(keys(local.vpc_cidr), local.cp_vpc_name) ? local.vpc_cidr[local.cp_vpc_name].primary : null
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [
    contains(keys(local.vpc_cidr), local.cp_vpc_name) ? cidrsubnet(local.vpc_cidr[local.cp_vpc_name].primary, 3, 1) : null,
    contains(keys(local.vpc_cidr), local.cp_vpc_name) ? cidrsubnet(local.vpc_cidr[local.cp_vpc_name].primary, 3, 2) : null,
    contains(keys(local.vpc_cidr), local.cp_vpc_name) ? cidrsubnet(local.vpc_cidr[local.cp_vpc_name].primary, 3, 3) : null
  ]

  public_subnets = [
    contains(keys(local.vpc_cidr), local.cp_vpc_name) ? cidrsubnet(local.vpc_cidr[local.cp_vpc_name].primary, 7, 4) : null,
    contains(keys(local.vpc_cidr), local.cp_vpc_name) ? cidrsubnet(local.vpc_cidr[local.cp_vpc_name].primary, 7, 5) : null,
    contains(keys(local.vpc_cidr), local.cp_vpc_name) ? cidrsubnet(local.vpc_cidr[local.cp_vpc_name].primary, 7, 6) : null
  ]

  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  public_dedicated_network_acl = true //Creates a dedicated network ACL and attaches to the public subnets

  enable_nat_gateway                  = false
  one_nat_gateway_per_az              = true
  create_multiple_public_route_tables = true

  public_subnet_tags = {
    SubnetType               = "Public"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    SubnetType                        = "Private"
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = merge({
    Terraform = "true"
  }, local.tags)
}

resource "aws_subnet" "tgw_private" {
  count = 3

  vpc_id                  = module.cluster_vpc.vpc_id
  cidr_block              = contains(keys(local.vpc_cidr), local.cp_vpc_name) ? cidrsubnet(local.vpc_cidr[local.cp_vpc_name].primary, 8, count.index + 4) : null
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge({
    Name       = "${local.cp_vpc_name}-tgw-private-${data.aws_availability_zones.available.names[count.index]}"
    SubnetType = "TGW-Private"
    Terraform  = "true"
    Cluster    = local.cp_vpc_name
  }, local.tags)
}

resource "aws_route_table_association" "tgw_private" {
  count          = 3
  subnet_id      = aws_subnet.tgw_private[count.index].id
  route_table_id = module.cluster_vpc.private_route_table_ids[count.index]
}

# Secondary CIDR for pods
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  vpc_id     = module.cluster_vpc.vpc_id
  cidr_block = local.vpc_cidr[local.cp_vpc_name].secondary
}

resource "aws_subnet" "pod_private" {
  count = 3

  vpc_id                  = module.cluster_vpc.vpc_id
  cidr_block              = contains(keys(local.vpc_cidr), local.cp_vpc_name) ? cidrsubnet(local.vpc_cidr[local.cp_vpc_name].secondary, 2, count.index) : null
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge({
    Name       = "${local.cp_vpc_name}-pod-private-${data.aws_availability_zones.available.names[count.index]}"
    SubnetType = "pod-private"
    Terraform  = "true"
    Cluster    = local.cp_vpc_name
  }, local.tags)
}
