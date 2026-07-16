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

  # IAM Identity Center authentication
  idc_instance_arn      = var.argocd_idc_instance_arn
  idc_region            = var.argocd_idc_region
  rbac_admin_identities = var.argocd_rbac_admin_identities

  # GitHub access via CodeConnections
  codeconnection_arn = var.argocd_codeconnection_arn

  tags = local.tags

  depends_on = [module.eks]
}
