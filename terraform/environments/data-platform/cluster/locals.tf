locals {
  eks_cluster_name              = "${local.application_name}-${local.environment}"
  eks_cloudwatch_log_group_name = "/aws/eks/${local.eks_cluster_name}/logs"
}
