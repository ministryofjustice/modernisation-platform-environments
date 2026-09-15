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

  base_domain = "container-platform.service.justice.gov.uk"

  # Double trimprefix due to mix of cloud-platform- and container-platform- prefixes
  workspace_slug = trimprefix(trimprefix(terraform.workspace, "cloud-platform-"), "container-platform-")
  cluster_domain = contains(local.mp_environments, terraform.workspace) ? "${local.workspace_slug}.${local.base_domain}" : "${local.cluster_name}.development.${local.base_domain}"

  #-----------------------------------------------------------------------------
  # ArgoCD GitOps control-plane configuration (ADR-002, ADR-015, US-015b).
  #
  # Relocated from argocd-gitops.tf and the former variables.tf so that resource
  # and data files carry no locals, matching the house convention used by
  # cert-manager/gatekeeper/etc. The resources that consume these live in
  # argocd-gitops.tf; the CodeConnection data source lives in data.tf.
  #-----------------------------------------------------------------------------

  # Detect if this cluster is an ArgoCD hub by checking the cluster tag.
  is_argocd_hub = lookup(data.aws_eks_cluster.cluster.tags, "argocd-role", "") == "hub"

  # CodeConnection ARN for the GitHub connection (looked up in data.tf, hub-only).
  argocd_codeconnection_arn = length(data.aws_codestarconnections_connection.github) > 0 ? data.aws_codestarconnections_connection.github[0].arn : ""

  # Shared monorepo for all BU workload manifests and baseline chart.
  #
  # The EKS-managed Argo CD capability runs in AWS-managed infrastructure and
  # cannot reach github.com directly — it clones repositories through the
  # CodeConnections git-http proxy.
  #
  # Proxy URL format (see AWS docs — "Connect to Git repositories with AWS
  # CodeConnections"):
  #   https://codeconnections.<region>.amazonaws.com/git-http/<account-id>/<region>/<connection-id>/<org>/<repo>
  environments_repo_org  = "ministryofjustice"
  environments_repo_name = "container-platform-environments"

  # Connection ID is the last path segment of the CodeConnection ARN
  # (arn:aws:codeconnections:<region>:<account>:connection/<connection-id>)
  argocd_codeconnection_id = element(reverse(split("/", local.argocd_codeconnection_arn)), 0)

  environments_repo = "https://codeconnections.${data.aws_region.current.region}.amazonaws.com/git-http/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.region}/${local.argocd_codeconnection_id}/${local.environments_repo_org}/${local.environments_repo_name}.git"

  # BU configuration — defines the spoke clusters and path within the monorepo
  # Each BU gets a nonlive and live AppProject + ApplicationSet pair
  # All BUs share the same source repo; isolation is via path prefix + AppProject destinations
  bu_configs = {
    octo = {
      clusters = {
        nonlive = "container-platform-octo-nonlive"
        live    = "container-platform-octo-live"
      }
    }
    laa = {
      clusters = {
        nonlive = "container-platform-laa-nonlive"
        live    = "container-platform-laa-live"
      }
    }
    hmpps = {
      clusters = {
        nonlive = "container-platform-hmpps-nonlive"
        live    = "container-platform-hmpps-live"
      }
    }
    cd = {
      clusters = {
        nonlive = "container-platform-cd-nonlive"
        live    = "container-platform-cd-live"
      }
    }
  }

  # Flatten BU configs into per-environment AppProject entries
  bu_appprojects = merge([
    for bu_name, bu_config in local.bu_configs : {
      for env, cluster_workspace in bu_config.clusters :
      "${bu_name}-${env}" => {
        bu_name           = bu_name
        environment       = env
        source_repo       = local.environments_repo
        cluster_workspace = cluster_workspace
        # Path prefix within monorepo for this BU's products
        path_prefix = "namespaces/${bu_name}"
        # Cluster ARN constructed from account ID + cluster name
        cluster_arn = "arn:aws:eks:eu-west-2:${local.environment_management.account_ids[cluster_workspace]}:cluster/${cluster_workspace}"
        auto_sync   = env == "nonlive" ? true : false
      }
    }
  ]...)

  #-----------------------------------------------------------------------------
  # Hub tier scoping (ADR-002 — dual-hub isolation)
  #
  # A hub must only register the spokes it owns: the nonlive hub manages nonlive
  # spokes, the live hub manages live spokes. Without this, every hub creates
  # ArgoCD control-plane objects (AppProjects, ApplicationSets and — critically
  # — cluster registration Secrets) for the OTHER tier's spokes, breaking tier
  # isolation.
  #
  # Permanent hubs derive their tier from the workspace name (last segment,
  # computed as local.workspace_environment: "nonlive" or "live"). Ephemeral
  # dev hubs (cluster_environment == "development_cluster") are not a permanent
  # tier and must NOT register any real BU spoke — they register only their
  # convention-paired spoke, "<hub-workspace-minus-hub-suffix>spoke".
  #-----------------------------------------------------------------------------
  hub_tier = local.workspace_environment == "live" ? "live" : "nonlive"

  is_ephemeral_hub = local.cluster_environment == "development_cluster"

  # Real BU spokes this permanent hub owns — its own tier only. Empty on
  # ephemeral hubs (they own no real spokes).
  hub_bu_appprojects = local.is_ephemeral_hub ? {} : {
    for key, spoke in local.bu_appprojects : key => spoke
    if spoke.environment == local.hub_tier
  }

  # Convention-paired ephemeral spoke for a dev hub: same account/region,
  # "<prefix>-spoke" derived from the hub's "<prefix>-hub" workspace name.
  ephemeral_spoke_workspace = replace(terraform.workspace, "-hub", "-spoke")
  ephemeral_spoke_registration = local.is_ephemeral_hub ? {
    "${local.ephemeral_spoke_workspace}" = {
      bu_name           = "ephemeral"
      environment       = "nonlive"
      source_repo       = local.environments_repo
      cluster_workspace = local.ephemeral_spoke_workspace
      path_prefix       = "namespaces/ephemeral"
      cluster_arn       = "arn:aws:eks:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.ephemeral_spoke_workspace}"
      auto_sync         = true
    }
  } : {}

  # Spokes this hub registers: its tier's real BU spokes (permanent hub) or its
  # single convention-paired spoke (ephemeral hub).
  hub_registered_spokes = merge(local.hub_bu_appprojects, local.ephemeral_spoke_registration)
}
