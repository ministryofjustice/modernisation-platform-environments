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

  cp_vpc_name           = local.cluster_environment == "development_cluster" ? "cloud-platform-development" : terraform.workspace
  workspace_environment = element(reverse(split("-", terraform.workspace)), 0)
  cluster_name          = contains(local.mp_environments, terraform.workspace) ? local.workspace_environment : terraform.workspace
  cluster_environment   = contains(local.mp_environments, terraform.workspace) ? local.workspace_environment : "development_cluster"

  base_domain_map = {
    development_cluster = "development.container-platform.service.justice.gov.uk"
    live                = "live.container-platform.service.justice.gov.uk"
  }
  cluster_base_domain = local.base_domain_map[local.cluster_environment]
}
