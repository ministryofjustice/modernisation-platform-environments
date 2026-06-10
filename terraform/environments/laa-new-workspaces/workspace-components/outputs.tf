##############################################
### Outputs for VPC and Subnets
### These are consumed by the main laa-workspaces config via remote state
##############################################

output "vpc_id" {
  description = "The ID of the WorkSpaces VPC"
  value       = local.environment == "development" ? aws_vpc.workspaces.id : null
}

output "vpc_cidr_block" {
  description = "The CIDR block of the WorkSpaces VPC"
  value       = local.environment == "development" ? aws_vpc.workspaces.cidr_block : null
}

output "private_subnet_a_id" {
  description = "The ID of private subnet A"
  value       = local.environment == "development" ? aws_subnet.private_a.id : null
}

output "private_subnet_b_id" {
  description = "The ID of private subnet B"
  value       = local.environment == "development" ? aws_subnet.private_b.id : null
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.environment == "development" ? [aws_subnet.private_a.id, aws_subnet.private_b.id] : []
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = try(aws_nat_gateway.main.id, null)
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP"
  value       = try(aws_eip.nat.public_ip, null)
}