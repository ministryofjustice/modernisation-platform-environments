variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "internal" {
  description = "whether the LB is internal or not. Defaults to `true`"
  type        = bool
  default     = true
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
  type = object({
    shared_vpc_cidr               = string
    shared_vpc_id                 = string
    private_subnet_ids            = list(string)
    ordered_private_subnet_ids    = list(string)
    public_subnet_ids             = list(string)
    data_subnet_ids               = list(string)
    data_subnet_a_id              = string
    route53_inner_zone_info       = any
    route53_network_services_zone = any
    route53_external_zone         = any
    kms_keys = object({
      ebs_shared     = any
      general_shared = any
      rds_shared     = any
    })
    general_shared_kms_key_arn = optional(string)
  })
  default = {
    shared_vpc_cidr                = "default_shared_vpc_cidr"
    shared_vpc_id                  = "default_shared_vpc_id"
    private_subnet_ids             = ["default_private_subnet_ids"]
    ordered_private_subnet_ids     = []
    public_subnet_ids              = ["default_public_subnet_ids"]
    data_subnet_ids                = ["default_data_subnet_ids"]
    data_subnet_a_id               = "default_data_subnet_id"
    route53_inner_zone_info        = {}
    route53_network_services_zone  = {}
    route53_external_zone          = {}
    migration_environment_vpc_cidr = "default_migration_environment_vpc_cidr"
    general_shared_kms_key_arn     = "default_general_shared_kms_key_arn"
    kms_keys = {
      ebs_shared     = {}
      general_shared = {}
      rds_shared     = {}
    }
  }
}

variable "environment_config" {
  type = object({
    migration_environment_private_cidr = optional(list(string))
    migration_environment_db_cidr      = optional(list(string))
    legacy_engineering_vpc_cidr        = string
    ec2_user_ssh_key                   = string
  })
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

variable "weblogic_config" {
  type = object({
    name                          = string
    frontend_service_name         = string
    frontend_fully_qualified_name = string
    frontend_image_tag            = string
    frontend_container_port       = number
    frontend_url_suffix           = string
    db_name                       = string
  })
  default = {
    name                          = "default_name"
    frontend_service_name         = "default_frontend_service_name"
    frontend_fully_qualified_name = "default_frontend_fully_qualified_name"
    frontend_image_tag            = "default_frontend_image_tag"
    frontend_container_port       = 8080
    frontend_url_suffix           = "default_frontend_url_suffix"
    db_name                       = "default_db_name"
  }
}

variable "tags" {
  type = any
}

variable "platform_vars" {
  type = object({
    environment_management = any
  })
}

variable "delius_db_container_config" {
  type = object({
    image_tag            = string
    image_name           = string
    fully_qualified_name = string
    port                 = number
    name                 = string
  })
  default = {
    image_tag            = "5.7.4"
    image_name           = "delius-core-testing-db"
    fully_qualified_name = "testing-db"
    port                 = 1521
    name                 = "MODNDA"
  }

}

variable "bastion_config" {
  type = any
}

variable "environments_in_account" {
  type    = list(string)
  default = []
}