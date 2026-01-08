locals {
  /* worksapce specific configurations */
  enabled_workspaces        = ["development_cluster"]
  # environment_configuration = local.environment_configurations[local.cluster_environment]
  # below are replaced for dev clusters
  cp_vpc_name         = "${local.application_name}-${local.environment}" # replaced with "cp-date-time" or custom name
  cluster_name        = local.environment                                # replaced with "cp-date-time" or custom name
  cluster_environment = local.environment                                # replaced with "development_cluster"
  # end replacements
}
