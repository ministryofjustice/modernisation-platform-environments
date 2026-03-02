locals {
  /* internal-development needs to use development network resources and EKS, so here we map it to the development environment */
  mapped_environment = local.environment == "internal-development" ? "development" : local.environment

  eks_cluster_name = "${local.application_name}-${local.mapped_environment}"

  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]
}