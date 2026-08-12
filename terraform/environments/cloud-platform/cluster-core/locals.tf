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
  # ArgoCD GitOps control-plane configuration (relocated from argocd-gitops.tf
  # and variables.tf so that resource files carry no locals, matching the house
  # convention used by cert-manager/gatekeeper/etc.).
  #
  # See ADR-002, ADR-015, US-015b. The resources that consume these live in
  # argocd-gitops.tf.
  #-----------------------------------------------------------------------------

  # Detect if this cluster is an ArgoCD hub by checking the cluster tag.
  # The argocd-role=hub tag is written by the cluster/ component
  # (cluster/eks-cluster.tf) when enable_argocd=true — this is a cross-component
  # dependency: cluster/ must be applied before this file does anything.
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

  # BU configuration — defines the spoke clusters and path within the monorepo.
  # Each BU gets a nonlive and live AppProject + ApplicationSet pair.
  # All BUs share the same source repo; isolation is via path prefix + AppProject destinations.
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
  }

  # Flatten BU configs into per-environment AppProject entries.
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
        auto_sync   = env == "nonlive"
      }
    }
  ]...)
}
