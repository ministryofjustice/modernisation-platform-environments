resource "aws_subnet" "eks_private" {
  count = 3

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = cidrsubnet(lookup(local.cp_vpc_cidr, terraform.workspace), 3, count.index + 4)
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

resource "aws_route_table_association" "eks_private" {
  count = 3

  subnet_id      = aws_subnet.eks_private[count.index].id
  route_table_id = module.vpc.private_route_table_ids[count.index]
}