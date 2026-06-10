data "aws_eks_cluster" "cluster" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}
