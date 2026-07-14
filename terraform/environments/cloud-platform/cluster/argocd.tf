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
  codeconnection_arn = var.argocd_codeconnection_arn

  # Enable pre-destroy cleanup for dev clusters (prevents cluster deletion hang)
  # Production hubs should set this to false to prevent accidental capability removal
  enable_destroy_cleanup = local.cluster_environment == "development_cluster"

  tags = local.tags

  depends_on = [module.eks]
}

###############################################################################
# Argo CD — Spoke Cluster Registration (ADR-002 — Spoke-Driven Model)
#
# When this cluster is designated as a spoke (argocd_register_as_spoke = true),
# it grants the hub's ArgoCD spoke-access role an EKS Access Entry with
# AmazonEKSClusterAdminPolicy. This allows the hub's managed ArgoCD to
# deploy workloads to this cluster without VPC peering or TGW.
#
# The hub's role ARN is determined by convention:
#   arn:aws:iam::<hub-account-id>:role/<hub-cluster-name>-argocd-spoke-access
#
# This can be overridden via var.argocd_hub_spoke_access_role_arn for cases
# where the hub doesn't follow the naming convention (e.g., testing with an
# ephemeral dev cluster as hub).
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
  # Resolve the hub spoke-access role ARN: explicit override takes precedence,
  # otherwise use the convention-based construction from hub config in locals.tf
  resolved_hub_spoke_access_role_arn = coalesce(
    var.argocd_hub_spoke_access_role_arn,
    local.argocd_hub_spoke_access_role_arn
  )

  # A cluster is a spoke if:
  # 1. Explicitly flagged via variable, OR
  # 2. The workspace is a BU account (listed in accounts.json) — these are
  #    always spokes by convention
  # A cluster cannot be both a hub and a spoke.
  is_argocd_spoke = (
    var.argocd_register_as_spoke || contains(local.bu_accounts.accounts, terraform.workspace)
  ) && !var.enable_argocd
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
