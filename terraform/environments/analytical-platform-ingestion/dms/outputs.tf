output "source_endpoint_arn" {
  value = aws_dms_endpoint.source_endpoint.arn
}

output "target_endpoint_arn" {
  value = aws_dms_s3_endpoint.arn
}

output "replication_instance_arn" {
  value = aws_dms_replication_instance.replication_instance.arn
}

output "replication_task_id" {
  value = aws_dms_replication_task.replication_task.id
}

