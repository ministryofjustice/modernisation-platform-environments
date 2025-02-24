output "source_endpoint_arn" {
  value = "arn:aws:dms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:endpoint/${aws_dms_endpoint.source_endpoint.id}"
}

# output "target_endpoint_arn" {
#   value = aws_dms_s3_endpoint.
# }

output "replication_instance_arn" {
  value = "arn:aws:dms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rep:replication-instance-${aws_dms_replication_instance.replication_instance.id}"
}

output "replication_task_id" {
  value = "arn:aws:dms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task:${aws_dms_replication_task.replication_task.id}"
}

