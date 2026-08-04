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

  node_role_name = split("/", data.aws_eks_cluster.cluster.compute_config[0].node_role_arn)[1]

  # Observability-specific configuration
  amp_workspace_alias = "${local.cluster_name}-metrics"

  # Feature flags — resolved from variables (default false, opt-in via -var flags)
  enable_amp_adot                 = var.enable_amp_adot
  enable_cloudwatch_observability = var.enable_cloudwatch_observability
  enable_amg                      = var.enable_amg
}
