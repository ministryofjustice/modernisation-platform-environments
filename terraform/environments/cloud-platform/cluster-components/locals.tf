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
  cluster_name          = terraform.workspace
  cluster_environment   = contains(local.mp_environments, terraform.workspace) ? local.workspace_environment : "development_cluster"

  base_domain = "container-platform.service.justice.gov.uk"

  # Double trimprefix due to mix of cloud-platform- and container-platform- prefixes
  workspace_slug = trimprefix(trimprefix(terraform.workspace, "cloud-platform-"), "container-platform-")
  cluster_domain = contains(local.mp_environments, terraform.workspace) ? "${local.workspace_slug}.${local.base_domain}" : "${local.cluster_name}.development.${local.base_domain}"

  # Observability-specific configuration
  amp_workspace_alias = "${local.cluster_name}-metrics"

  # Observability feature flags — resolved from variables (default false, opt-in via -var flags)
  enable_amp_adot                 = var.enable_amp_adot
  enable_cloudwatch_observability = var.enable_cloudwatch_observability
  enable_amg                      = var.enable_amg
}
