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
  type = list(
    object(
      {
        name           = string
        ami_name_regex = string
        user_data_raw  = optional(string)
        instance = object({
          associate_public_ip_address  = optional(bool, false)
          disable_api_termination      = bool
          instance_type                = string
          metadata_endpoint_enabled    = optional(string, "enabled")
          metadata_options_http_tokens = optional(string, "required")
          monitoring                   = optional(bool, true)
          ebs_block_device_inline      = optional(bool, false)
          vpc_security_group_ids       = list(string)
          private_dns_name_options = optional(object({
            enable_resource_name_dns_aaaa_record = optional(bool)
            enable_resource_name_dns_a_record    = optional(bool)
            hostname_type                        = string
          }))
        })
        ebs_volumes = optional(object({
          kms_key_id = string
          tags       = map(string)
          iops       = number
          throughput = number
          root_volume = object({
            volume_type = string
            volume_size = number
          })
          ebs_non_root_volumes = map(object({
            volume_type = optional(string)
            volume_size = optional(string)
            no_device   = optional(bool)
          }))
        }))
        route53_records = object({
          create_internal_record = bool
          create_external_record = bool
        })
      }
    )
  )
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
  type = object({
    api_image_tag = string
    ui_image_tag  = string
  })
  default = {
    api_image_tag = "default_image_tag"
    ui_image_tag  = "default_image_tag"
  }
}

variable "weblogic_config" {
  type = any
}

variable "weblogic_eis_config" {
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