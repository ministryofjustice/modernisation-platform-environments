output "fabric_oidc_provider_arn" {
  description = "ARN of the Microsoft Entra OIDC provider for Fabric."
  value       = module.fabric_oidc_provider.arn
}

output "fabric_iam_role_arn" {
  description = "ARN of the IAM role for Fabric."
  value       = module.fabric_iam_role.arn
}