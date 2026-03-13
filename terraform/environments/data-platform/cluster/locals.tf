locals {
  environment_configuration = local.environment_configurations[local.environment]
  cluster_configuration     = yamldecode(file("${path.module}/configuration/cluster.yml"))["environment"][local.environment]

  eks_cluster_name                    = "${local.application_name}-${local.environment}"
  eks_cluster_logs_log_group_name     = "/aws/eks/${local.eks_cluster_name}/cluster"
  eks_application_logs_log_group_name = "/aws/eks/${local.eks_cluster_name}/application"

  aps_log_group_name = "/aws/aps/${local.eks_cluster_name}"

  container_insights_log_group_name = "/aws/containerinsights/${local.eks_cluster_name}/performance"
}
