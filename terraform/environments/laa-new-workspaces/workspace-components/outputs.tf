##############################################
### Outputs for root module consumption
##############################################

output "vpc_id" {
  description = "ID of the WorkSpaces VPC"
  value       = aws_vpc.workspaces.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the WorkSpaces VPC"
  value       = aws_vpc.workspaces.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets for Active Directory"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "radius_shared_secret_arn" {
  description = "ARN of the RADIUS shared secret in Secrets Manager"
  value       = aws_secretsmanager_secret.radius_shared_secret.arn
}

output "radius_server_private_ips" {
  description = "Private IP addresses of RADIUS servers"
  value       = [aws_instance.radius_server.private_ip]
}

output "ses_sender_email" {
  description = "SES sender email address for notifications"
  value       = "no-reply@${aws_ses_domain_identity.workspaces.domain}"
}

output "radius_portal_url" {
  description = "URL of the RADIUS MFA self-service portal"
  value       = "https://${aws_route53_record.radius_portal.name}"
}

###############################################
# Outputs for AWS Network Firewall
###############################################

output "network_firewall_policy_arn" {
  description = "ARN of the WorkSpaces Network Firewall policy for web filtering"
  value       = try(aws_networkfirewall_firewall_policy.workspaces_web_allowlist.arn, null)
}

output "network_firewall_id" {
  description = "ID of the WorkSpaces Network Firewall"
  value       = try(aws_networkfirewall_firewall.workspaces_web_allowlist.id, null)
}

output "network_firewall_endpoint_ids" {
  description = "Endpoint IDs for the WorkSpaces Network Firewall"
  value = try(
    [for sync_state in aws_networkfirewall_firewall.workspaces_web_allowlist.firewall_status[0].sync_states : sync_state.endpoint_id],
    []
  )
}

###############################################
# Outputs for LinOTP ECS Infrastructure
###############################################

output "ecs_cluster_id" {
  description = "ID of the ECS cluster for LinOTP"
  value       = aws_ecs_cluster.workspaces.id
}

output "ecs_linotp3_security_group_id" {
  description = "Security group ID for LinOTP ECS tasks"
  value       = aws_security_group.ecs_linotp3.id
}

output "linotp3_db_endpoint" {
  description = "RDS endpoint for LinOTP 3.x database"
  value       = aws_db_instance.linotp3.endpoint
}

output "linotp3_enc_key_secret_arn" {
  description = "ARN of LinOTP 3.x encryption key secret"
  value       = aws_secretsmanager_secret.linotp3_enc_key.arn
}

output "linotp3_db_password_secret_arn" {
  description = "ARN of LinOTP 3.x database password secret"
  value       = aws_secretsmanager_secret.linotp3_db_password.arn
}

output "linotp_admin_password_arn" {
  description = "ARN of LinOTP admin password secret"
  value       = aws_secretsmanager_secret.linotp_admin_password.arn
}

output "ad_admin_password_secret_arn" {
  description = "ARN of AD admin password secret (used for LDAP bind)"
  value       = data.aws_secretsmanager_secret.ad_admin_password.arn
}

output "linotp_portal_target_group_arn" {
  description = "ARN of the LinOTP portal target group"
  value       = aws_lb_target_group.linotp3_portal.arn
}

output "radius_nlb_target_group_arn" {
  description = "ARN of the RADIUS NLB target group for ECS"
  value       = aws_lb_target_group.radius_ecs.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecr_linotp3_repository_url" {
  description = "URL of the LinOTP 3.x ECR repository"
  value       = aws_ecr_repository.linotp3.repository_url
}

output "ecr_freeradius_repository_url" {
  description = "URL of the FreeRADIUS ECR repository"
  value       = aws_ecr_repository.freeradius_linotp.repository_url
}

output "ecs_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs_linotp3.name
}

