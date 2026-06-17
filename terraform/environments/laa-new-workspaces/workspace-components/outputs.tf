##############################################
### Outputs for VPC and Subnets
### These are consumed by the main laa-workspaces config via remote state
##############################################

output "vpc_id" {
  description = "The ID of the WorkSpaces VPC"
  value       = aws_vpc.workspaces.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the WorkSpaces VPC"
  value       = aws_vpc.workspaces.cidr_block
}

output "private_subnet_a_id" {
  description = "The ID of private subnet A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "The ID of private subnet B"
  value       = aws_subnet.private_b.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = try(aws_nat_gateway.main.id, null)
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP"
  value       = try(aws_eip.nat.public_ip, null)
}

##############################################
### RADIUS Server Outputs
##############################################

output "radius_server_security_group_id" {
  description = "Security group ID for RADIUS servers"
  value       = aws_security_group.radius_server.id
}

output "radius_server_iam_role_arn" {
  description = "IAM role ARN for RADIUS servers"
  value       = aws_iam_role.radius_server.arn
}

output "radius_server_private_ip" {
  description = "Private IP address of RADIUS server"
  value       = aws_instance.radius_server.private_ip
}

output "radius_server_id" {
  description = "Instance ID of RADIUS server"
  value       = aws_instance.radius_server.id
}

output "radius_shared_secret_arn" {
  description = "ARN of the RADIUS shared secret in Secrets Manager"
  value       = aws_secretsmanager_secret.radius_shared_secret.arn
  sensitive   = true
}

output "radius_alb_dns_name" {
  description = "DNS name of the RADIUS portal ALB"
  value       = aws_lb.radius_portal.dns_name
}

output "radius_portal_url" {
  description = "URL of the LinOTP MFA self-service portal"
  value       = "https://${aws_route53_record.radius_portal.fqdn}"
}

output "linotp_admin_password_arn" {
  description = "ARN of the LinOTP admin password in Secrets Manager"
  value       = aws_secretsmanager_secret.linotp_admin_password.arn
  sensitive   = true
}

output "mariadb_root_password_arn" {
  description = "ARN of the MariaDB root password in Secrets Manager"
  value       = aws_secretsmanager_secret.mariadb_root_password.arn
  sensitive   = true
}

output "ses_sender_email" {
  description = "SES verified sender email address"
  value       = "no-reply@${aws_ses_domain_identity.workspaces.domain}"
}
