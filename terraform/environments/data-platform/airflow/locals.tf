locals {
  eks_cluster_name = "${local.application_name}-${local.environment}-airflow"

  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]
}
