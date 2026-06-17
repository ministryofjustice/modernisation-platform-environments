data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [terraform.workspace]
  }
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}
