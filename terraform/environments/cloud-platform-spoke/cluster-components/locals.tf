locals {
  mp_environments = [
    "cloud-platform-spoke-preproduction",
    "cloud-platform-spoke-nonlive",
    "cloud-platform-spoke-live",
  ]
  cp_vpc_name         = terraform.workspace
  cluster_name        = contains(local.mp_environments, terraform.workspace) ? local.environment : terraform.workspace
  cluster_environment = contains(local.mp_environments, terraform.workspace) ? local.environment : "development"
}
