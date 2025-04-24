locals {
  # lookup kms_key_ids, subnet ids and lookup security group ids
  fsx_windows = {
    for key, value in var.fsx_windows : key => merge(value, {
      kms_key_id          = try(var.environment.kms_keys[value.kms_key_id].arn, value.kms_key_id)
      preferred_subnet_id = value.preferred_availability_zone != null ? var.environment.subnet[value.preferred_subnet_name][value.preferred_availability_zone].id : null
      subnet_ids = flatten([
        for subnet in value.subnets : [
          for az in subnet.availability_zones : [
            var.environment.subnet[subnet.name][az].id
          ]
        ]
      ])
      security_group_ids = [for sg in value.security_groups : try(aws_security_group.this[sg].id, sg)]
    })
  }
}

module "fsx_windows" {
  for_each = local.fsx_windows

  source = "../../modules/fsx_windows"

  name                              = each.key
  active_directory_id               = each.value.active_directory_id
  aliases                           = each.value.aliases
  automatic_backup_retention_days   = each.value.automatic_backup_retention_days
  backup_id                         = each.value.backup_id
  daily_automatic_backup_start_time = each.value.daily_automatic_backup_start_time
  deployment_type                   = each.value.deployment_type
  kms_key_id                        = each.value.kms_key_id
  preferred_subnet_id               = each.value.preferred_subnet_id
  security_group_ids                = each.value.security_group_ids
  self_managed_active_directory     = each.value.self_managed_active_directory
  skip_final_backup                 = each.value.skip_final_backup
  storage_capacity                  = each.value.storage_capacity
  storage_type                      = each.value.storage_type
  subnet_ids                        = each.value.subnet_ids
  throughput_capacity               = each.value.throughput_capacity
  weekly_maintenance_start_time     = each.value.weekly_maintenance_start_time

  tags = merge(local.tags, each.value.tags)
}
