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
    [for sync_state in aws_networkfirewall_firewall.workspaces_web_allowlist.firewall_status.sync_states : sync_state.endpoint_id],
    []
  )
}

