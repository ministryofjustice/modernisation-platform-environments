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
  # ArgoCD Hub Configuration (ADR-002 — dual-hub model)
  #
  # Permanent hubs (development + production) are located by convention: spokes
  # construct the hub's spoke-access role ARN from the hub identity for their
  # environment tier. No manual input is needed for these.
  #
  # Ephemeral/test hubs are NOT covered by the convention — for those, the
  # engineer passes the hub role ARN explicitly as a workflow input, which
  # arrives as var.argocd_hub_spoke_access_role_arn and takes precedence.
  #
  # IMPORTANT: cluster_name MUST equal the hub cluster's Terraform workspace
  # name, because the hub's role is created as "<workspace>-argocd-spoke-access"
  # (see modules/argo-cd — aws_iam_role.argocd_spoke_access).
  #-----------------------------------------------------------------------------
  argocd_hubs = {
    nonlive = {
      account_id   = local.environment_management.account_ids["cloud-platform-development"]
      cluster_name = "cloud-platform-development"
    }
    live = {
      account_id   = local.environment_management.account_ids["cloud-platform-live"]
      cluster_name = "cloud-platform-live"
    }
  }

  # Environment tier of this spoke (last segment of the workspace name).
  argocd_spoke_tier = local.workspace_environment == "live" ? "live" : "nonlive"

  # Convention-based hub role ARN for this spoke's tier.
  argocd_hub_convention_role_arn = "arn:aws:iam::${local.argocd_hubs[local.argocd_spoke_tier].account_id}:role/${local.argocd_hubs[local.argocd_spoke_tier].cluster_name}-argocd-spoke-access"
}
