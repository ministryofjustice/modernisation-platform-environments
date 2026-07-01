# GitHub Actions OIDC Role ARN - Added manually to CFO-DataManagementSystem repository
output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC authentication — set as AWS_ROLE_ARN in the CFO-DataManagementSystem repository environment secrets"
  value       = module.github-actions-oidc-role.role
}

# EICE endpoint ID - use with `aws ec2-instance-connect open-tunnel` to reach private resources
output "eice_endpoint_id" {
  description = "EC2 Instance Connect Endpoint ID — use to tunnel to RDS or other private VPC resources"
  value       = aws_ec2_instance_connect_endpoint.main.id
}
