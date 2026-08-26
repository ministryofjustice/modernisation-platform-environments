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

  ## Read from the VPC tag set by the network component, which owns this flag
  ## because the SSM relay lives there. Defaults to false if the tag is absent.
  private_endpoint_mode = lookup(data.aws_vpc.selected.tags, "private-endpoint-mode", "false") == "true"

  # ArgoCD is enabled on hub clusters (identified by workspace name in argocd_hubs)
  # or via TF_VAR for ephemeral test hubs.
  enable_argocd = var.enable_argocd || local.is_argocd_hub_cluster

  #-----------------------------------------------------------------------------
  # ArgoCD Hub Configuration (ADR-002 — dual-hub model)
  #
  # Permanent hubs (development + production) are located by convention: spokes
  # construct the hub's Argo CD Capability role ARN from the hub identity for
  # their environment tier. No manual input is needed for these.
  #
  # Ephemeral/test hubs are NOT covered by the convention — for those, the
  # engineer passes the hub role ARN explicitly as a workflow input, which
  # arrives as var.argocd_hub_capability_role_arn and takes precedence.
  #
  # IMPORTANT: cluster_name MUST equal the hub cluster's Terraform workspace
  # name, because the hub's role is created as "<workspace>-argocd-capability"
  # (see modules/argo-cd — aws_iam_role.argocd_capability).
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

  # Convention-based hub Argo CD Capability role ARN for this spoke's tier.
  argocd_hub_capability_convention_role_arn = "arn:aws:iam::${local.argocd_hubs[local.argocd_spoke_tier].account_id}:role/${local.argocd_hubs[local.argocd_spoke_tier].cluster_name}-argocd-capability"

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
  # The ADMIN mapping is always present and grants two IDC groups:
  #   - cloud-platform-engineers: the platform team.
  #   - container-platform-aws: the AWS ProServe team, so they can access the
  #     ArgoCD portal on hub clusters.
  # Additional per-tier mappings (EDITOR/VIEWER for BU teams) come from the
  # environment_configurations map, keyed ADMIN/EDITOR/VIEWER -> list of
  # { id, type } IDC identities.
  #
  # Group IDs are hardcoded because the ModernisationPlatformSSOReadOnly role
  # returns ResourceNotFoundException when calling GetGroupId despite having
  # identitystore:Get*. TODO: switch back to a data.aws_identitystore_group
  # lookup.
  #-----------------------------------------------------------------------------
  cloud_platform_engineers_group_id = "664252b4-7021-701e-49b9-6c46ccc7899e"
  container_platform_aws_group_id   = "7682a204-00f1-7031-257e-713bb28289c6"

  argocd_rbac_role_mappings = merge(
    {
      ADMIN = [
        { id = local.cloud_platform_engineers_group_id, type = "SSO_GROUP" },
        { id = local.container_platform_aws_group_id, type = "SSO_GROUP" },
      ]
    },
    lookup(local.environment_configuration, "argocd_rbac_role_mappings", {})
  )

  #-----------------------------------------------------------------------------
  # Derived ArgoCD hub/spoke booleans and role ARN (relocated from argocd.tf so
  # that resource files carry no locals, matching the house convention).
  #-----------------------------------------------------------------------------
  # A cluster never self-identifies as both hub and spoke.
  is_argocd_hub_cluster = contains(values(local.argocd_hubs)[*].cluster_name, terraform.workspace)

  # Ephemeral dev spoke — self-identifies by the "-spoke" suffix, strictly
  # scoped to development_cluster. This mirrors the hub side (cluster-core/
  # argocd-gitops.tf, issue #8457), where an ephemeral hub derives its paired
  # spoke from the "-hub"/"-spoke" convention. No argocd_registered_spokes entry
  # and no hub-ARN workflow input are required: an ephemeral hub/spoke pair
  # shares a prefix and an account, so each partner is derivable from the
  # workspace name. Confined to development_cluster so it can never affect a
  # permanent cluster.
  is_argocd_ephemeral_spoke = (
    local.cluster_environment == "development_cluster" &&
    endswith(terraform.workspace, "-spoke")
  )

  # Permanent spoke — must be explicitly listed in argocd_registered_spokes for
  # its tier AND be a known permanent cluster. The allowlist is a deliberate,
  # reviewed opt-in: a permanent cluster does not grant a hub elevated access to
  # itself just because the hub exists, and it also gates phased BU onboarding.
  is_argocd_permanent_spoke = contains(
    lookup(local.environment_configuration, "argocd_registered_spokes", []),
    terraform.workspace
  ) && contains(local.mp_environments, terraform.workspace)

  # This cluster registers with a hub if it is either a permanent registered
  # spoke or an ephemeral convention spoke, and is not itself a hub.
  is_argocd_spoke = (
    (local.is_argocd_permanent_spoke || local.is_argocd_ephemeral_spoke) &&
    !local.enable_argocd &&
    !local.is_argocd_hub_cluster
  )

  # Ephemeral hub paired with this ephemeral spoke: "<prefix>-hub" in the SAME
  # account. Its Argo CD Capability role follows the module naming convention
  # "<hub-workspace>-argocd-capability" (see modules/argo-cd).
  argocd_ephemeral_hub_workspace           = replace(terraform.workspace, "-spoke", "-hub")
  argocd_ephemeral_hub_capability_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.argocd_ephemeral_hub_workspace}-argocd-capability"

  # Hub's Argo CD Capability role ARN, resolved in precedence order:
  #   1. Explicit override (var.argocd_hub_capability_role_arn) — escape hatch,
  #      e.g. an ephemeral spoke pairing with a non-convention hub.
  #   2. Ephemeral convention — the paired "<prefix>-hub" in this account.
  #   3. Permanent convention — the tier hub (nonlive/live) from local.argocd_hubs.
  resolved_hub_capability_role_arn = (
    var.argocd_hub_capability_role_arn != "" ? var.argocd_hub_capability_role_arn :
    local.is_argocd_ephemeral_spoke ? local.argocd_ephemeral_hub_capability_role_arn :
    local.argocd_hub_capability_convention_role_arn
  )

  # Kubernetes RBAC group that the hub capability role is placed into on this spoke.
  # The access entry declares this group explicitly via kubernetes_groups (EKS
  # does NOT auto-create an "eks-access-entry:<arn>" group), and the custom
  # ClusterRoles below bind to it. This is how we grant scoped access without
  # attaching AmazonEKSClusterAdminPolicy.
  #
  # Must be a valid Kubernetes group name (<= 63 chars), so it is a short fixed
  # label rather than anything derived from the role ARN.
  argocd_hub_capability_rbac_group = "argocd-hub"
}
