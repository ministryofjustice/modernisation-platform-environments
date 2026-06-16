locals {
  mp_environments = [
    "cloud-platform-preproduction",
    "cloud-platform-nonlive",
    "cloud-platform-live",
    "container-platform-octo-nonlive",
    "container-platform-octo-live"
  ]

  cp_vpc_name         = local.cluster_environment == "development_cluster" ? "cloud-platform-development" : terraform.workspace
  cluster_name        = contains(local.mp_environments, terraform.workspace) ? local.environment : terraform.workspace
  cluster_environment = contains(local.mp_environments, terraform.workspace) ? local.environment : "development_cluster"
}
