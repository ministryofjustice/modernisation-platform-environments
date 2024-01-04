output "dms_instance_name" {
  value = var.name
}

output "dms_replication_instance_arn" {
  value = var.setup_dms_instance ? join("", aws_dms_replication_instance.dms-s3-target-instance.*.replication_instance_arn) : ""
}

output "dms_subnet_ids" {
  value = var.subnet_ids
}