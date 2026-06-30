# GitHub Actions OIDC Role ARN - Added manually to CFO-DataManagementSystem repository
output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC authentication — set as AWS_ROLE_ARN in the CFO-DataManagementSystem repository environment secrets"
  value       = module.github-actions-oidc-role.role
}
