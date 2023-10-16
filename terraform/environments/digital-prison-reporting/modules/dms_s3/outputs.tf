output "dms_subnet_ids" {
  value = var.subnet_ids
}

output "dms_instance_name" {
  value = var.name
}

output "dms_replication_task_name" {
  value = "${var.project_id}-dms-task-${var.short_name}-${var.dms_source_name}-${var.dms_target_name}"
}