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
  # ArgoCD RBAC role mappings (layer 1 of the BU-user access model — ADR-002).
  #
  # This layer controls who can LOG IN to the ArgoCD UI. It does not, on its
  # own, make any Applications visible: global VIEWER gates ArgoCD itself, not
  # project-scoped resources. Application visibility is layer 2, the per-BU
  # AppProject `roles` grant in cluster-core/argocd-gitops.tf. Both layers key
  # on the same BU parent group. See ADR-002 "BU-User ArgoCD UI Access".
  #
  # ADMIN — always present, grants two IDC groups:
  #   - cloud-platform-engineers: the platform team.
  #   - container-platform-aws: the AWS ProServe team.
  # These two IDs stay HARDCODED on purpose: ADMIN is the lock-out-prevention
  # path, so it must not depend on the sso-readonly data source resolving at
  # plan time.
  #
  # VIEWER — the onboarded BU parent groups (cloud-platform#8548). Keyed on
  # group NAME; IDs are resolved from data.aws_identitystore_groups (ListGroups,
  # see data.tf) so no BU group ID is hardcoded and the reviewable source of
  # truth is the name. A name that does not resolve is dropped rather than
  # failing the plan, so a renamed/removed group cannot break the hub.
  #
  # Static by design: these are BU PARENT groups (children of the GitHub
  # `business-units` team). Squad teams nest under their BU parent and inherit
  # membership, so onboarding a new squad needs no change here — only onboarding
  # a brand-new BU does.
  #-----------------------------------------------------------------------------
  cloud_platform_engineers_group_id = "664252b4-7021-701e-49b9-6c46ccc7899e"
  container_platform_aws_group_id   = "7682a204-00f1-7031-257e-713bb28289c6"

  # BU parent group NAMES that receive read-only ArgoCD UI access, one per
  # onboarded BU (matches local.bu_configs in cluster-core). See ADR-002
  # "Groups in use" — octo→office-of-the-cto and cd→central-digital are inferred
  # from child-team naming; hmpps/laa are exact.
  argocd_viewer_bu_group_names = [
    "office-of-the-cto", # octo
    "laa",               # laa
    "hmpps-developers",  # hmpps
    "central-digital",   # cd
  ]

  # Resolve group name -> IDC group ID (only on hubs, where the lookup runs).
  argocd_idc_group_id_by_name = local.enable_argocd ? {
    for g in data.aws_identitystore_groups.all[0].groups : g.display_name => g.group_id
  } : {}

  # VIEWER identities: resolved BU parent groups. Names that do not resolve are
  # skipped (defensive — a mistyped/removed group must not fail the hub plan).
  argocd_viewer_identities = [
    for name in local.argocd_viewer_bu_group_names :
    { id = local.argocd_idc_group_id_by_name[name], type = "SSO_GROUP" }
    if contains(keys(local.argocd_idc_group_id_by_name), name)
  ]

  argocd_rbac_role_mappings = merge(
    {
      ADMIN = [
        { id = local.cloud_platform_engineers_group_id, type = "SSO_GROUP" },
        { id = local.container_platform_aws_group_id, type = "SSO_GROUP" },
      ]
      VIEWER = local.argocd_viewer_identities
    },
    # Optional per-tier override. No tier sets this key today, so the lookup
    # returns {} and the baseline above stands. NOTE: merge is shallow — if a
    # tier ever sets a role key here (e.g. VIEWER), it REPLACES the baseline
    # list for that role, it does not append. Add to argocd_viewer_bu_group_names
    # for BU access; reserve this override for genuine per-tier exceptions.
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
