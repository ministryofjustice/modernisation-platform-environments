###############################################################################
# Argo CD Module — Outputs
###############################################################################

output "capability_arn" {
  description = "ARN of the Argo CD EKS Capability"
  value       = aws_eks_capability.argocd.arn
}

output "capability_role_arn" {
  description = "ARN of the IAM role used by the Argo CD Capability"
  value       = aws_iam_role.argocd_capability.arn
}

output "spoke_access_role_arn" {
  description = "ARN of the IAM role for cross-account spoke cluster access"
  value       = aws_iam_role.argocd_spoke_access.arn
}

output "spoke_access_role_name" {
  description = "Name of the IAM role for cross-account spoke cluster access"
  value       = aws_iam_role.argocd_spoke_access.name
}
