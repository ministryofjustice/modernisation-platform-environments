locals {
  common = {
    environment_name = var.environment_name
    subnet_ids       = var.subnet_ids
    tags             = var.tags
    vpc_id           = var.vpc_id
    region           = var.region
  }
  fsx = {
    automatic_backup_retention_days    = 7
    common_name                        = var.environment_name
    copy_tags_to_backups               = false
    daily_automatic_backup_start_time  = "03:00"
    deployment_type                    = "MULTI_AZ_1"
    filesystem_name                    = var.environment_name
    storage_capacity                   = var.storage_capacity
    throughput_capacity                = var.throughput_capacity
  }
}