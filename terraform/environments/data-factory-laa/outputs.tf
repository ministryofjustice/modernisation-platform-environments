# Phase 1 of a two-phase deployment: these outputs are disabled until the
# fabric_oidc_provider and fabric_iam_role modules in fabric.tf are re-enabled.
# output "fabric_oidc_provider_arn" {
#   description = "ARN of the Microsoft Entra OIDC provider for Fabric."
#   value       = module.fabric_oidc_provider.arn
# }
#
# output "fabric_iam_role_arn" {
#   description = "ARN of the IAM role for Fabric."
#   value       = module.fabric_iam_role.arn
# }