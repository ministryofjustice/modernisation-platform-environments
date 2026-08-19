###############################################################################
# Argo CD Module — Outputs
###############################################################################

output "capability_arn" {
  description = "ARN of the Argo CD EKS Capability"
  value       = aws_eks_capability.argocd.arn
}

output "capability_role_arn" {
  description = "ARN of the IAM role used by the Argo CD Capability. Spokes register this role directly as their EKS Access Entry."
  value       = aws_iam_role.argocd_capability.arn
}
