locals {
  bu_accounts = jsondecode(file("${path.module}/../accounts.json"))

  mp_environments = concat(
    [
      "cloud-platform-preproduction",
      "cloud-platform-nonlive",
      "cloud-platform-live"
    ],
    local.bu_accounts.accounts
  )

  environment_configuration = local.environment_configurations[local.cluster_environment]
  cp_vpc_name               = local.cluster_environment == "development_cluster" ? "cloud-platform-development" : terraform.workspace
  cluster_name              = contains(local.mp_environments, terraform.workspace) ? local.environment : terraform.workspace
  cluster_environment       = contains(local.mp_environments, terraform.workspace) ? local.environment : "development_cluster"
}
