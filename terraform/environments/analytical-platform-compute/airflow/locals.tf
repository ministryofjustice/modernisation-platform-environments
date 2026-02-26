locals {
  eks_cluster_name = "${local.application_name}-${local.environment}"
  # Sandbox Airflow will use development networking resources.
  networking_environment = local.environment == "sandbox" ? "development" : local.environment

  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]
}
