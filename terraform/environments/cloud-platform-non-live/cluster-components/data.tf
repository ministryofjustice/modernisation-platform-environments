data "aws_eks_cluster" "cluster" {
  name = local.environment
}