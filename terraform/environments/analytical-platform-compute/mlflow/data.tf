data "aws_vpc" "apc" {
  tags = {
    "Name" = "${local.application_name}-${local.environment}"
  }
}

data "aws_subnets" "apc_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.apc.id]
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-private*"
  }
}

data "aws_subnet" "apc_private" {
  for_each = toset(data.aws_subnets.apc_private.ids)
  id       = each.value
}

data "aws_db_subnet_group" "apc" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_eks_cluster" "eks" {
  name = local.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}
