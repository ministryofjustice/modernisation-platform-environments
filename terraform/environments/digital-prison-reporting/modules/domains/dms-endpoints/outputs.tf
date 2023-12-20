output "dms_target_endpoint_arn" {
  value = var.setup_dms_endpoints && var.setup_dms_s3_endpoint ? join("", aws_dms_endpoint.dms-s3-target-endpoint.*.endpoint_arn): ""
}

output "dms_source_endpoint_arn" {
  value = var.setup_dms_endpoints && var.setup_dms_nomis_endpoint ? join("", aws_dms_endpoint.dms-s3-target-source.*.endpoint_arn): ""
}

output "dms_s3_iam_policy_admin_arn" {
  description = "The IAM Policy (ARN) admin of the DMS to S3 target"
  value       = concat(aws_iam_policy.dms-operator-s3-policy.*.arn, [""])[0]
}