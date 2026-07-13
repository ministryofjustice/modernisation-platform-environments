###############################################################################
# Cluster Outputs
###############################################################################

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

#------------------------------------------------------------------------------
# Argo CD Outputs (only populated when enable_argocd = true)
#------------------------------------------------------------------------------
output "argocd_capability_arn" {
  description = "ARN of the Argo CD EKS Capability (empty if ArgoCD not enabled)"
  value       = var.enable_argocd ? module.argocd[0].capability_arn : ""
}

output "argocd_spoke_access_role_arn" {
  description = "ARN of the IAM role for spoke cluster access (register this in spoke Access Entries)"
  value       = var.enable_argocd ? module.argocd[0].spoke_access_role_arn : ""
}
