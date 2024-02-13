variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

# Account level info
variable "account_info" {
  type = object({
    business_unit    = string,
    region           = string,
    vpc_id           = string,
    application_name = string,
    mp_environment   = string,
    id               = string
  })
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

variable "db_config" {
  type = any
}

variable "gdpr_config" {
  type = object({
    api_image_tag = string
    ui_image_tag  = string
  })
  default = {
    api_image_tag = "default_image_tag"
    ui_image_tag  = "default_image_tag"
  }
}

variable "merge_config" {
  type = any
}

variable "weblogic_config" {
  type = any
}

variable "weblogic_eis_config" {
  type = any
}

variable "user_management_config" {
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

variable "community_api" {
  type = object({
    name           = string
    image_tag      = string
    container_port = number
    host_port      = number
    protocol       = string
    db_name        = string
  })
  default = {
    name           = "community-api"
    image_tag      = "default_image_tag"
    container_port = 8080
    host_port      = 8080
    protocol       = "tcp"
    db_name        = "default_db_name"
  }
}
