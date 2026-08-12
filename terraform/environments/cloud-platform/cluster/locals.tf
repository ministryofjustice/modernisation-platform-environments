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

  # ArgoCD is enabled on hub clusters (identified by workspace name in argocd_hubs)
  # or via TF_VAR for ephemeral test hubs.
  enable_argocd = var.enable_argocd || local.is_argocd_hub_cluster

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
      account_id   = local.environment_management.account_ids["cloud-platform-nonlive"]
      cluster_name = "cloud-platform-nonlive"
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

  #-----------------------------------------------------------------------------
  # ArgoCD authentication constants (previously variables — never overridden).
  #-----------------------------------------------------------------------------
  # Org-wide IAM Identity Center instance — the same ARN across all MoJ accounts.
  argocd_idc_instance_arn = "arn:aws:sso:::instance/ssoins-7535d9af4f41fb26"
  # Region of the IAM Identity Center instance.
  argocd_idc_region = "eu-west-2"

  #-----------------------------------------------------------------------------
  # ArgoCD RBAC role mappings.
  #
  # The ADMIN mapping to the cloud-platform-engineers IDC group is always
  # present. Additional per-tier mappings (EDITOR/VIEWER for BU teams) come from
  # the environment_configurations map, keyed ADMIN/EDITOR/VIEWER -> list of
  # { id, type } IDC identities.
  #
  # cloud_platform_engineers_group_id is hardcoded because the
  # ModernisationPlatformSSOReadOnly role returns ResourceNotFoundException when
  # calling GetGroupId despite having identitystore:Get* — see cluster/data.tf
  # history. TODO: switch back to a data.aws_identitystore_group lookup.
  #-----------------------------------------------------------------------------
  cloud_platform_engineers_group_id = "664252b4-7021-701e-49b9-6c46ccc7899e"

  argocd_rbac_role_mappings = merge(
    {
      ADMIN = [{ id = local.cloud_platform_engineers_group_id, type = "SSO_GROUP" }]
    },
    lookup(local.environment_configuration, "argocd_rbac_role_mappings", {})
  )

  #-----------------------------------------------------------------------------
  # Derived ArgoCD hub/spoke booleans and role ARN (relocated from argocd.tf so
  # that resource files carry no locals, matching the house convention).
  #-----------------------------------------------------------------------------
  # Hub's spoke-access role ARN — resolved by convention or explicit override.
  resolved_hub_spoke_access_role_arn = (
    var.argocd_hub_spoke_access_role_arn != ""
    ? var.argocd_hub_spoke_access_role_arn
    : local.argocd_hub_convention_role_arn
  )

  # A cluster never self-identifies as both hub and spoke.
  is_argocd_hub_cluster = contains(values(local.argocd_hubs)[*].cluster_name, terraform.workspace)

  # Spoke registration: workspace must appear in the argocd_registered_spokes
  # allowlist AND must not be a hub AND must be a known permanent cluster (or
  # have an explicit hub ARN for ephemeral spokes).
  is_argocd_spoke = contains(
    lookup(local.environment_configuration, "argocd_registered_spokes", []),
    terraform.workspace
    ) && !local.enable_argocd && !local.is_argocd_hub_cluster && (
    contains(local.mp_environments, terraform.workspace) || var.argocd_hub_spoke_access_role_arn != ""
  )
}
