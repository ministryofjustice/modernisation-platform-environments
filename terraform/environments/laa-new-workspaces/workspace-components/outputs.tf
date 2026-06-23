##############################################
### Outputs for root module consumption
##############################################

output "vpc_id" {
  description = "ID of the WorkSpaces VPC"
  value       = aws_vpc.workspaces.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets for Active Directory"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "radius_shared_secret_arn" {
  description = "ARN of the RADIUS shared secret in Secrets Manager"
  value       = aws_secretsmanager_secret.radius_shared_secret.arn
}
