###############################################################################
# Argo CD — Hub Cluster EKS Capability (ADR-002)
#
# Conditionally enables the AWS-managed Argo CD Capability on this cluster.
# Set var.enable_argocd = true to designate this cluster as a hub.
#
# References:
#   - ADR-002: GitOps Fleet Management — EKS Capability for Argo CD
#   - US-015a: Provision Hub Cluster to support Argo CD Deployment
###############################################################################

# Resolve CodeConnections ARN: explicit variable > data source lookup
# TODO: rename to data.aws_codeconnections_connection when the AWS provider adds
# the data source equivalent (currently only the resource exists under that name).
data "aws_codestarconnections_connection" "github" {
  count = var.argocd_codeconnection_arn == "" && var.enable_argocd ? 1 : 0
  name  = "github-ministryofjustice"
}

locals {
  resolved_codeconnection_arn = var.argocd_codeconnection_arn != "" ? var.argocd_codeconnection_arn : try(data.aws_codestarconnections_connection.github[0].arn, "")
}

module "argocd" {
  source = "./modules/argo-cd"
  count  = var.enable_argocd ? 1 : 0

  cluster_name = module.eks.cluster_name
  cluster_arn  = module.eks.cluster_arn

  # IAM Identity Center authentication and RBAC
  #
  # Role mappings are constructed from two sources:
  # 1. argocd_admin_group_id — the platform-engineer-admin group (ADMIN)
  # 2. argocd_rbac_role_mappings — additional groups at any role level
  #
  # At scale, BU teams are added as VIEWER or EDITOR groups via
  # argocd_rbac_role_mappings. This map is passed from a tfvars file or
  # from the bu_configs when BU onboarding creates their IDC group.
  idc_instance_arn = var.argocd_idc_instance_arn
  idc_region       = var.argocd_idc_region
  rbac_role_mappings = merge(
    # Platform admin group
    var.argocd_admin_group_id != "" ? {
      ADMIN = [{ id = var.argocd_admin_group_id, type = "SSO_GROUP" }]
    } : {},
    # Additional role mappings (BU teams as VIEWER/EDITOR)
    var.argocd_rbac_role_mappings
  )

  # GitHub access via CodeConnections
  codeconnection_arn = local.resolved_codeconnection_arn

  # Enable pre-destroy cleanup for dev clusters (prevents cluster deletion hang)
  # Production hubs should set this to false to prevent accidental capability removal
  enable_destroy_cleanup = local.cluster_environment == "development_cluster"

  tags = local.tags

  depends_on = [module.eks]
}

###############################################################################
# Argo CD — Spoke Cluster Registration (ADR-002 — Spoke-Driven Model)
#
# Any non-hub cluster is a spoke (see local.is_argocd_spoke). A spoke grants
# the hub's ArgoCD spoke-access role an EKS Access Entry with
# AmazonEKSClusterAdminPolicy. This allows the hub's managed ArgoCD to deploy
# workloads to this cluster without VPC peering or TGW.
#
# The hub's role ARN is resolved by local.resolved_hub_spoke_access_role_arn:
#   - Permanent hubs (development/production): convention-based, no input needed
#   - Ephemeral/test hubs: engineer passes the ARN as a workflow input
#     (TF_VAR_argocd_hub_spoke_access_role_arn), which takes precedence.
#
# Cross-account: EKS Access Entries natively support cross-account IAM
# principals — no VPC peering, TGW, or additional IAM trust policy changes
# required on the spoke side.
#
# References:
#   - ADR-002: GitOps Fleet Management — Spoke Access Model
#   - US-015b: Spoke Registration and GitOps Configuration
###############################################################################

locals {
  # Resolve the hub spoke-access role ARN:
  # 1. Explicit workflow input (var) — used for ephemeral/test hubs
  # 2. Convention-based ARN for the spoke's tier — used for permanent hubs
  resolved_hub_spoke_access_role_arn = var.argocd_hub_spoke_access_role_arn != "" ? var.argocd_hub_spoke_access_role_arn : local.argocd_hub_convention_role_arn

  # Any cluster that is not the hub is a spoke — provided we know which hub to
  # register with. That is true when either:
  #   1. This is a permanent cluster (in mp_environments) → hub known by convention, OR
  #   2. An explicit hub role ARN was supplied (ephemeral/test clusters)
  # Hub clusters (preproduction, live) are never spokes — even before ArgoCD is
  # enabled on them. Ephemeral clusters without an explicit hub ARN are neither
  # hub nor spoke, so they do not attempt registration.
  is_argocd_hub_cluster = contains(values(local.argocd_hubs)[*].cluster_name, terraform.workspace)

  is_argocd_spoke = !var.enable_argocd && !local.is_argocd_hub_cluster && (
    contains(local.mp_environments, terraform.workspace) || var.argocd_hub_spoke_access_role_arn != ""
  )
}

resource "aws_eks_access_entry" "argocd_spoke" {
  count = local.is_argocd_spoke ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = local.resolved_hub_spoke_access_role_arn
  type          = "STANDARD"

  tags = merge(local.tags, {
    Name    = "${module.eks.cluster_name}-argocd-spoke-access"
    Purpose = "argocd-hub-spoke-registration"
  })

  lifecycle {
    precondition {
      condition     = local.resolved_hub_spoke_access_role_arn != ""
      error_message = "Could not resolve the ArgoCD hub spoke-access role ARN. For a permanent hub, ensure the tier is present in local.argocd_hubs; for an ephemeral hub, pass the ARN via the workflow input (TF_VAR_argocd_hub_spoke_access_role_arn)."
    }
  }
}

resource "aws_eks_access_policy_association" "argocd_spoke" {
  count = local.is_argocd_spoke ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = local.resolved_hub_spoke_access_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.argocd_spoke]
}
