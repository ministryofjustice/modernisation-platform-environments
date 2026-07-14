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
  workspace_environment     = element(reverse(split("-", terraform.workspace)), 0)
  cluster_name              = terraform.workspace
  cluster_environment       = contains(local.mp_environments, terraform.workspace) ? local.workspace_environment : "development_cluster"

  #-----------------------------------------------------------------------------
  # ArgoCD Hub Configuration (ADR-002)
  #
  # Defines the hub cluster's identity for spoke registration. Spoke clusters
  # construct the hub's spoke-access role ARN from this configuration using a
  # predictable naming convention: <hub_cluster_name>-argocd-spoke-access
  #
  # This is infrastructure configuration, not dynamic discovery. When the hub
  # moves from development to a dedicated production account, update these
  # values and re-apply spoke clusters.
  #-----------------------------------------------------------------------------
  argocd_hub = {
    account_id   = local.environment_management.account_ids["cloud-platform-development"]
    cluster_name = "development" # Stable hub cluster name (update when permanent hub is provisioned)
  }

  # Constructed spoke-access role ARN for the hub — used by spoke registration
  argocd_hub_spoke_access_role_arn = "arn:aws:iam::${local.argocd_hub.account_id}:role/${local.argocd_hub.cluster_name}-argocd-spoke-access"
}
