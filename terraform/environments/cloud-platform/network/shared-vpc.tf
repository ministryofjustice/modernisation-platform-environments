module "cluster_vpc" {
  version = "6.5.1"
  source  = "terraform-aws-modules/vpc/aws"
  count   = terraform.workspace == "cloud-platform-development" ? 1 : 0

  name = local.cp_vpc_name
  cidr = lookup(local.vpc_cidr, local.cp_vpc_name)
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [
    cidrsubnet(lookup(local.vpc_cidr, local.cp_vpc_name), 8, 1),
    cidrsubnet(lookup(local.vpc_cidr, local.cp_vpc_name), 8, 2),
    cidrsubnet(lookup(local.vpc_cidr, local.cp_vpc_name), 8, 3)
  ]

  public_subnets = [
    cidrsubnet(lookup(local.vpc_cidr, local.cp_vpc_name), 7, 0),
    cidrsubnet(lookup(local.vpc_cidr, local.cp_vpc_name), 7, 1),
    cidrsubnet(lookup(local.vpc_cidr, local.cp_vpc_name), 7, 2)
  ]

  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  public_dedicated_network_acl = true //Creates a dedicated network ACL and attaches to the public subnets

  enable_nat_gateway                  = false
  one_nat_gateway_per_az              = true
  create_multiple_public_route_tables = true

  public_subnet_tags = {
    SubnetType = "Public"
  }

  private_subnet_tags = {
    SubnetType = "TGW-Private"
  }

  tags = merge({
    Terraform = "true"
  }, local.tags)
}

resource "aws_subnet" "eks_private_subnet" {
  count = terraform.workspace == "cloud-platform-development" ? 3 : 0

  vpc_id                  = module.cluster_vpc[0].vpc_id
  cidr_block              = cidrsubnet(lookup(local.vpc_cidr, local.cp_vpc_name), 3, count.index + 4)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge({
    Name                              = "${local.cp_vpc_name}-eks-private-${data.aws_availability_zones.available.names[count.index]}"
    SubnetType                        = "EKS-Private"
    "kubernetes.io/role/internal-elb" = "1"
    Terraform                         = "true"
    Cluster                           = local.cp_vpc_name
    # Domain                            = local.vpc_base_domain_name
  }, local.tags)
}

resource "aws_route_table_association" "eks_private_route" {
  count = terraform.workspace == "cloud-platform-development" ? 3 : 0

  subnet_id      = aws_subnet.eks_private_subnet[count.index].id
  route_table_id = module.cluster_vpc[0].private_route_table_ids[count.index]
}
