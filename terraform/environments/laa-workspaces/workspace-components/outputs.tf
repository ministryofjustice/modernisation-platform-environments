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
  description = "Private IP addresses of RADIUS servers (empty until instances are deployed)"
  value       = [] # Will be populated when aws_instance.radius_server is uncommented
  # value = try([for instance in aws_instance.radius_server : instance.private_ip], [])
}

output "radius_server_ids" {
  description = "Instance IDs of RADIUS servers (empty until instances are deployed)"
  value       = [] # Will be populated when aws_instance.radius_server is uncommented
  # value = try([for instance in aws_instance.radius_server : instance.id], [])
}

output "radius_shared_secret_arn" {
  description = "ARN of the RADIUS shared secret in Secrets Manager"
  value       = try(aws_secretsmanager_secret.radius_shared_secret[0].arn, null)
  sensitive   = true
}
