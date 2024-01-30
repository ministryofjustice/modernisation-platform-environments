resource "aws_fsx_windows_file_system" "fsx" {

  #active_directory_id               = var.fsx.active_directory_id
  storage_capacity                  = var.fsx.storage_capacity
  throughput_capacity               = var.fsx.throughput_capacity
  subnet_ids                        = var.common.subnet_ids
  #preferred_subnet_id               = var.fsx.preferred_subnet_id
  automatic_backup_retention_days   = var.fsx.automatic_backup_retention_days
  copy_tags_to_backups              = var.fsx.copy_tags_to_backups
  daily_automatic_backup_start_time = var.fsx.daily_automatic_backup_start_time
  security_group_ids                = [aws_security_group.fsx.id]
  deployment_type                   = var.fsx.deployment_type
  fsx_admin_password                = var.fsx.fsx_admin_password # FSx admin password
  kms_key_id                        = var.common.kms_key_id 

  tags = merge(
    var.common.tags,
    {
      "Name" = var.fsx.filesystem_name
    }
  )

  # kms_key_id  = local.kms_key_id

  timeouts {
    create = "60m"
    delete = "60m"
  }

  # There is no FSx API for reading security_group_ids
  lifecycle {
    ignore_changes = [security_group_ids]
  }

}