output "replication_task_arn" {
  value = aws_dms_replication_task.dms-db-migration-task.replication_task_arn
}
