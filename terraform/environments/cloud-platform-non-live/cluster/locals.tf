locals {
  mp_environments = [
    "cloud-platform-non-live-development",
    "cloud-platform-non-live-test",
    "cloud-platform-non-live-preproduction",
    "cloud-platform-non-live-production"
  ]
  environment_configuration = local.environment_configurations[local.cluster_environment]
  enabled_workspaces        = ["development_cluster"]
  cp_vpc_name               = terraform.workspace
  cluster_name              = contains(local.mp_environments, terraform.workspace) ? local.environment : terraform.workspace
  cluster_environment       = contains(local.mp_environments, terraform.workspace) ? local.environment : "development_cluster"
}
