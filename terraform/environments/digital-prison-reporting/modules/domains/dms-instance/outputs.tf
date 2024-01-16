output "dms_subnet_ids" {
  value = var.setup_dms_instance ? module.dms_instance.dms_subnet_ids : []
}

output "dms_instance_name" {
  value = var.name
}

output "dms_replication_instance_arn" {
  value = var.setup_dms_instance ? module.dms_instance.dms_replication_instance_arn : ""
}
