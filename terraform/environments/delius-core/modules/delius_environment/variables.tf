variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

# Account level info
variable "account_info" {
  type = any
}

variable "account_config" {
  type = any
}

variable "environment_config" {
  type = any
}

variable "ldap_config" {
  type = object({
    name                        = string
    encrypted                   = bool
    migration_source_account_id = string
    migration_lambda_role       = string
    efs_throughput_mode         = string
    efs_provisioned_throughput  = string
    efs_backup_schedule         = string
    efs_backup_retention_period = string
    port                        = optional(number)
    tls_port                    = optional(number)
    desired_count               = number
    log_retention               = number
  })
  default = {
    name                        = "default_name"
    encrypted                   = true
    migration_source_account_id = "default_migration_source_account_id"
    migration_lambda_role       = "default_migration_lambda_role"
    efs_throughput_mode         = "default_efs_throughput_mode"
    efs_provisioned_throughput  = "default_efs_provisioned_throughput"
    efs_backup_schedule         = "default_efs_backup_schedule"
    efs_backup_retention_period = "default_efs_backup_retention_period"
    port                        = 389
    tls_port                    = 636
    desired_count               = 0
    log_retention               = 7
  }
}

variable "delius_microservice_configs" {
  type = any
}

variable "db_config" {
  type = any
}

variable "dms_config" {
  type = any
}

variable "tags" {
  type = any
}

variable "platform_vars" {
  type = object({
    environment_management = any
  })
}


variable "bastion_config" {
  type = any
}

variable "environments_in_account" {
  type    = list(string)
  default = []
}

variable "pagerduty_integration_key" {
  description = "Pager Duty Integration Key"
  type        = string
  default     = null
}

variable "ignore_changes_service_task_definition" {
  description = "Ignore changes to the task definition"
  type        = bool
  default     = true
}

variable "enable_platform_backups" {
  description = "Enable or disable Mod Platform centralised backups"
  type        = bool
  default     = null
}

variable "db_suffix" {
  description = "identifier to append to name e.g. dsd, boe"
  type        = string
  default     = "db"
}

variable "env_name_to_dms_config_map" {
  description = "Map of delius-core environments to DMS configurations"
  type        = any
}

# Only create one per account
variable "create_backup_role" {
  description = "Role used to run AWS Backups i.e. AWSBackupDefaultServiceRole"
  type        = bool
  default     = false
}

# Only create one per account
variable "create_ecs_lambda" {
  description = "Lambda that alerts probation-migrations-team Slack channel if ECS tasks are being retired"
  type        = bool
  default     = false
}