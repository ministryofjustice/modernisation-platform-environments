output "cortex_xsiam_role_arn" {
  value       = local.cortex_xsiam_enabled ? module.cortex_xsiam_role[0].arn : null
  description = "IAM role ARN to configure in Cortex XSIAM"
}

output "cortex_xsiam_sqs_url" {
  value       = local.is-production ? aws_sqs_queue.cortex_xsiam[0].url : null
  description = "SQS URL to configure in Cortex XSIAM"
}