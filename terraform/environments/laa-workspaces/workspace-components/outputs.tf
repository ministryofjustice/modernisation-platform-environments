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
### Outputs for KMS Keys
##############################################

output "kms_ebs_key_arn" {
  description = "ARN of the KMS key for EBS encryption"
  value       = local.environment == "development" ? aws_kms_key.ebs[0].arn : null
}

output "kms_ebs_key_id" {
  description = "ID of the KMS key for EBS encryption"
  value       = local.environment == "development" ? aws_kms_key.ebs[0].id : null
}

##############################################
### Outputs for IAM Roles
##############################################

output "workspaces_iam_role_arn" {
  description = "ARN of the WorkSpaces default IAM role"
  value       = local.environment == "development" ? aws_iam_role.workspaces_default[0].arn : null
}

output "workspaces_iam_role_name" {
  description = "Name of the WorkSpaces default IAM role"
  value       = local.environment == "development" ? aws_iam_role.workspaces_default[0].name : null
}

##############################################
### Outputs for Security Groups
##############################################

output "workspaces_security_group_id" {
  description = "ID of the WorkSpaces security group"
  value       = local.environment == "development" ? aws_security_group.workspaces[0].id : null
}
