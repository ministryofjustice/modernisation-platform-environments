##############################################
### Outputs for VPC and Subnets
### These are consumed by the main laa-workspaces config via remote state
##############################################

output "vpc_id" {
  description = "The ID of the WorkSpaces VPC"
  value       = local.environment == "development" ? aws_vpc.workspaces[0].id : null
}

output "vpc_cidr_block" {
  description = "The CIDR block of the WorkSpaces VPC"
  value       = local.environment == "development" ? aws_vpc.workspaces[0].cidr_block : null
}

output "private_subnet_a_id" {
  description = "The ID of private subnet A"
  value       = local.environment == "development" ? aws_subnet.private_a[0].id : null
}

output "private_subnet_b_id" {
  description = "The ID of private subnet B"
  value       = local.environment == "development" ? aws_subnet.private_b[0].id : null
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.environment == "development" ? [aws_subnet.private_a[0].id, aws_subnet.private_b[0].id] : []
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = try(aws_nat_gateway.main[0].id, null)
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP"
  value       = try(aws_eip.nat[0].public_ip, null)
}

###############################################
# Outputs for AWS Network Firewall
###############################################

output "network_firewall_policy_arn" {
  description = "ARN of the WorkSpaces Network Firewall policy for web filtering"
  value       = try(aws_networkfirewall_firewall_policy.workspaces_web_allowlist[0].arn, null)
}

output "network_firewall_id" {
  description = "ID of the WorkSpaces Network Firewall"
  value       = try(aws_networkfirewall_firewall.workspaces_web_allowlist[0].id, null)
}

output "network_firewall_endpoint_ids" {
  description = "Endpoint IDs for the WorkSpaces Network Firewall"
  value = try(
   [for sync_state in aws_networkfirewall_firewall.workspaces_web_allowlist[0].firewall_status[0].sync_states : sync_state.attachment[0].endpoint_id],
    []
  )
}

##############################################
### RADIUS Server Outputs
##############################################

output "radius_server_security_group_id" {
  description = "Security group ID for RADIUS servers"
  value       = try(aws_security_group.radius_server[0].id, null)
}

output "radius_server_iam_role_arn" {
  description = "IAM role ARN for RADIUS servers"
  value       = try(aws_iam_role.radius_server[0].arn, null)
}

output "radius_server_private_ips" {
  description = "Private IP addresses of RADIUS servers"
  value       = try([for instance in aws_instance.radius_server : instance.private_ip], [])
}

output "radius_server_ids" {
  description = "Instance IDs of RADIUS servers"
  value       = try([for instance in aws_instance.radius_server : instance.id], [])
}

output "radius_shared_secret_arn" {
  description = "ARN of the RADIUS shared secret in Secrets Manager"
  value       = try(aws_secretsmanager_secret.radius_shared_secret[0].arn, null)
  sensitive   = true
}

output "radius_alb_dns_name" {
  description = "DNS name of the RADIUS portal ALB"
  value       = try(aws_lb.radius_portal[0].dns_name, null)
}

output "radius_portal_url" {
  description = "URL of the LinOTP MFA self-service portal"
  value       = try("https://${aws_route53_record.radius_portal[0].fqdn}", null)
}

output "linotp_admin_password_arn" {
  description = "ARN of the LinOTP admin password in Secrets Manager"
  value       = try(aws_secretsmanager_secret.linotp_admin_password[0].arn, null)
  sensitive   = true
}

output "mariadb_root_password_arn" {
  description = "ARN of the MariaDB root password in Secrets Manager"
  value       = try(aws_secretsmanager_secret.mariadb_root_password[0].arn, null)
  sensitive   = true
}
