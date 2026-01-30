locals {
  mp_environments = [
    "cloud-platform-development",
    "cloud-platform-preproduction",
    "cloud-platform-nonlive",
    "cloud-platform-live",
  ]
  environment_configuration = local.environment_configurations[local.cluster_environment]
  enabled_workspaces        = ["development_cluster","preproduction","nonlive","live"]
  cp_vpc_name               = terraform.workspace
  cluster_name              = contains(local.mp_environments, terraform.workspace) ? local.environment : terraform.workspace
  cluster_environment       = contains(local.mp_environments, terraform.workspace) ? local.environment : "development_cluster"
}
