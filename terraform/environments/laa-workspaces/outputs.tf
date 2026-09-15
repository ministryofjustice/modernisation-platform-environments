##############################################
### Active Directory Outputs
### For workspace-components to reference
##############################################

output "ad_directory_id" {
  description = "Active Directory directory ID"
  value       = local.environment == "development" ? aws_directory_service_directory.workspaces_ad[0].id : null
}

output "ad_directory_name" {
  description = "Active Directory directory name (FQDN)"
  value       = local.environment == "development" ? aws_directory_service_directory.workspaces_ad[0].name : null
}

output "ad_dns_ips" {
  description = "Active Directory DNS server IP addresses"
  value       = local.environment == "development" ? aws_directory_service_directory.workspaces_ad[0].dns_ip_addresses : []
}

output "ad_security_group_id" {
  description = "Active Directory security group ID"
  value       = local.environment == "development" ? aws_directory_service_directory.workspaces_ad[0].security_group_id : null
}

output "lambda_workspace_password_parameter" {
  description = "SSM parameter name for lambda.workspace service account password"
  value       = local.environment == "development" ? "/laa-workspaces/${local.environment}/ad-service-account-password" : null
}
