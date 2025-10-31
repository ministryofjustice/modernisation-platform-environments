# DMS Instance
output "dms_instance_name" {
  value = var.name
}

output "dms_replication_instance_arn" {
  value = var.setup_dms_instance ? join("", aws_dms_replication_instance.dms-s3-target-instance.*.replication_instance_arn) : ""
}

output "dms_subnet_ids" {
  value = var.subnet_ids
}

# DMS TASK
output "dms_replication_task_name" {
  value = "${var.project_id}-dms-task-${var.short_name}-${var.dms_source_name}-${var.dms_target_name}"
}

output "dms_replication_task_arn" {
  value = var.enable_replication_task ? join("", aws_dms_replication_task.dms-replication.*.replication_task_arn) : ""
}

output "replication_task_id" {
  value = var.enable_replication_task ? join("", aws_dms_replication_task.dms-replication.*.replication_task_id) : ""
}

# DMS Endpoint
output "dms_target_endpoint_arn" {
  value = var.setup_dms_endpoints && var.setup_dms_s3_endpoint ? join("", aws_dms_s3_endpoint.dms-s3-target-endpoint.*.endpoint_arn) : ""
}

output "dms_source_endpoint_arn" {
  value = var.setup_dms_endpoints && var.setup_dms_source_endpoint ? join("", aws_dms_endpoint.dms-s3-target-source.*.endpoint_arn) : ""
}

output "dms_s3_iam_policy_admin_arn" {
  description = "The IAM Policy (ARN) admin of the DMS to S3 target"
  #value       = concat(aws_iam_policy.dms-operator-s3-policy.*.arn, [""])[0]
  value = var.setup_dms_endpoints && var.setup_dms_iam ? join("", aws_iam_policy.dms-operator-s3-policy.*.arn) : ""
}

output "dms_instance_log_group_arn" {
  description = "The ARM of the DMS instance log group"
  value       = var.setup_dms_endpoints && var.setup_dms_instance ? join("", aws_cloudwatch_log_group.dms-instance-log-group.*.arn) : ""
}