output "dms_subnet_ids" {
  value = var.subnet_ids
}

output "dms_instance_name" {
  value = var.name
}

output "dms_replication_task_name" {
  value = "${var.project_id}-dms-task-${var.short_name}-${var.dms_source_name}-${var.dms_target_name}"
}

output "dms_s3_iam_policy_admin_arn" {
  description = "The IAM Policy (ARN) admin of the DMS to S3 target"
  value       = concat(aws_iam_policy.dms-operator-s3-policy.*.arn, [""])[0]
}

output "dms_replication_task_arn" {
  value = var.enable_replication_task ? join("", aws_dms_replication_task.dms-replication.*.replication_task_arn) : ""
}

output "dms_target_endpoint_arn" {
  value = aws_dms_s3_endpoint.dms-s3-target-endpoint[0].endpoint_arn
}

output "dms_source_endpoint_arn" {
  value = aws_dms_endpoint.dms-s3-target-source[0].endpoint_arn
}