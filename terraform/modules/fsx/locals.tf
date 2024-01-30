locals {
  common = {
    environment_name = var.common.environment_name
    subnet_ids       = var.common.subnet_ids
    tags             = var.common.tags
    vpc_id           = var.common.vpc_id
    region           = var.common.region
  }
  fsx = {
    automatic_backup_retention_days    = 7
    common_name                        = var.fsx.environment_name
    copy_tags_to_backups               = false
    daily_automatic_backup_start_time  = "03:00"
    deployment_type                    = "MULTI_AZ_1"
    filesystem_name                    = var.fsx.environment_name
    storage_capacity                   = var.fsx.storage_capacity
    throughput_capacity                = var.fsx.throughput_capacity
  }
}