locals {
  mp_environments = [
    "cloud-platform-development",
    "cloud-platform-preproduction",
    "cloud-platform-nonlive",
    "cloud-platform-live",
  ]
  enabled_workspaces  = ["development_cluster"]
  cp_vpc_name         = terraform.workspace
  cluster_name        = contains(local.mp_environments, terraform.workspace) ? local.environment : terraform.workspace
  cluster_environment = contains(local.mp_environments, terraform.workspace) ? local.environment : "development_cluster"
}
