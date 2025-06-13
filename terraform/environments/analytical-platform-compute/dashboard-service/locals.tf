locals {
  /* EKS */
  eks_cluster_name = "${local.application_name}-${local.environment}"

  environment_map = {
    "test"       = "development",
    "production" = "data-production"
  }
  analytical_platform_environment = format(
    "analytical-platform-%s",
    lookup(local.environment_map, local.environment, local.environment)
  )
  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]
}
