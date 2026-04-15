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
