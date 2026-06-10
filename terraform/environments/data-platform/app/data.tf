data "aws_eks_cluster" "cluster" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_vpc" "eks" {
  id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
}

data "aws_subnets" "eks_data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-data*"]
  }
}
