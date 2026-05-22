output "custom_idp_function_name" {
  description = "Future custom identity provider Lambda function name."
  value       = var.enable_custom_idp ? module.lambda_custom_idp[0].lambda_function_name : null
}

output "custom_idp_function_arn" {
  description = "Future custom identity provider Lambda function ARN."
  value       = var.enable_custom_idp ? module.lambda_custom_idp[0].lambda_function_arn : null
}

output "custom_idp_users_table_name" {
  description = "Users table name reserved for a future custom identity provider."
  value       = var.enable_custom_idp ? local.custom_idp_users_table_name : null
}

output "custom_idp_identity_providers_table_name" {
  description = "Identity providers table name reserved for a future custom identity provider."
  value       = var.enable_custom_idp ? local.custom_idp_identity_providers_table_name : null
}