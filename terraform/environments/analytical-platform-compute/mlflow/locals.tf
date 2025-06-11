locals {
  environment_configuration = local.environment_configurations[local.environment]
  eks_cluster_name          = "${local.application_name}-${local.environment}"
}
