output "dms_replication_task_name" {
  value = var.enable_replication_task ? var.name : ""
}

output "dms_replication_task_arn" {
  value = var.enable_replication_task ? module.dms_task.dms_replication_task_arn : ""
}

output "replication_task_id" {
  value = var.enable_replication_task ? module.dms_task.replication_task_id : ""
} 