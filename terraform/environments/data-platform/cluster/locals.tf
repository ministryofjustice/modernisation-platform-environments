locals {
  eks_cluster_name                    = "${local.application_name}-${local.environment}"
  eks_cluster_logs_log_group_name     = "/aws/eks/${local.eks_cluster_name}/cluster"
  eks_application_logs_log_group_name = "/aws/eks/${local.eks_cluster_name}/application"
}
