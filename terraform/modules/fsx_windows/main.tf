resource "aws_fsx_windows_file_system" "this" {
  active_directory_id               = var.active_directory_id
  aliases                           = var.aliases
  automatic_backup_retention_days   = var.automatic_backup_retention_days
  backup_id                         = var.backup_id
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  deployment_type                   = var.deployment_type
  kms_key_id                        = var.kms_key_id
  preferred_subnet_id               = var.preferred_subnet_id
  security_group_ids                = var.security_group_ids
  skip_final_backup                 = var.skip_final_backup
  storage_capacity                  = var.storage_capacity
  storage_type                      = var.storage_type
  subnet_ids                        = var.subnet_ids
  throughput_capacity               = var.throughput_capacity
  weekly_maintenance_start_time     = var.weekly_maintenance_start_time

  dynamic "self_managed_active_directory" {
    for_each = var.self_managed_active_directory != null ? [var.self_managed_active_directory] : []
    content {
      dns_ips                                = self_managed_active_directory.value.dns_ips
      domain_name                            = self_managed_active_directory.value.domain_name
      password                               = local.domain_join_password
      username                               = self_managed_active_directory.value.username
      file_system_administrators_group       = self_managed_active_directory.value.file_system_administrators_group
      organizational_unit_distinguished_name = self_managed_active_directory.value.organizational_unit_distinguished_name
    }
  }
  tags = merge(var.tags, {
    Name = var.name
  })
}
