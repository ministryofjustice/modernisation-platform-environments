output "dms_target_endpoint_arn" {
  value = var.setup_dms_endpoints && var.setup_dms_s3_endpoint ? module.dms_endpoints.dms_target_endpoint_arn : ""
}

output "dms_source_endpoint_arn" {
  value = var.setup_dms_endpoints && var.setup_dms_source_endpoint ? module.dms_endpoints.dms_source_endpoint_arn : ""
}

output "dms_s3_iam_policy_admin_arn" {
  description = "The IAM Policy (ARN) admin of the DMS to S3 target"
  value       = module.dms_endpoints.dms_s3_iam_policy_admin_arn
}