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
  }
}

variable "delius_microservice_configs" {
  type = any
}

variable "db_config" {
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

variable "sns_topic_name" {
  description = "SNS topic name"
  type        = string
  default     = "delius-core-alarms-topic"
}

variable "pagerduty_integration_key" {
  description = "Pager Duty Integration Key"
  type        = string
  default     = null
}
