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
    mp_environment   = string
  })
}

variable "network_config" {
  type = object({
    shared_vpc_cidr                = string
    private_subnet_ids             = list(string)
    private_subnet_a_id            = string
    route53_inner_zone_info        = any
    migration_environment_vpc_cidr = optional(string)
    general_shared_kms_key_arn     = optional(string)
  })
  default = {
    shared_vpc_cidr                = "default_shared_vpc_cidr"
    private_subnet_ids             = ["default_private_subnet_ids"]
    private_subnet_a_id            = "default_private_subnet_id"
    route53_inner_zone_info        = {}
    migration_environment_vpc_cidr = "default_migration_environment_vpc_cidr"
    general_shared_kms_key_arn      = "default_general_shared_kms_key_arn"
  }
}

variable "ldap_config" {
  type = object({
    name                        = string
    migration_source_account_id = string
    migration_lambda_role       = string
    efs_throughput_mode         = string
    efs_provisioned_throughput  = string
    efs_backup_schedule         = string
    efs_backup_retention_period = string

  })
  default = {
    name                        = "default_name"
    migration_source_account_id = "default_migration_source_account_id"
    migration_lambda_role       = "default_migration_lambda_role"
    efs_throughput_mode         = "default_efs_throughput_mode"
    efs_provisioned_throughput  = "default_efs_provisioned_throughput"
    efs_backup_schedule         = "default_efs_backup_schedule"
    efs_backup_retention_period = "default_efs_backup_retention_period"
  }
}

variable "db_config" {
  type = object({
    name                 = string
    ami_name             = string
    ami_owner            = string
    user_data_raw        = optional(string, null)
    instance = object({
      associate_public_ip_address  = optional(bool, false)
      disable_api_termination      = bool
      instance_type                = string
      key_name                     = string
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
    ebs_volume_config = map(object({
      iops       = optional(number)
      throughput = optional(number)
      total_size = optional(number)
      type       = optional(string)
      kms_key_id = optional(string)
    }))
    ebs_volumes = map(object({
      label       = optional(string)
      snapshot_id = optional(string)
      iops        = optional(number)
      throughput  = optional(number)
      size        = optional(number)
      type        = optional(string)
      kms_key_id  = optional(string)
    }))
    route53_records = object({
      create_internal_record = bool
      create_external_record = bool
    })
  })
  default = {
    name = "name_example"
    ami_name             = "ami_name_example"
    ami_owner            = "ami_owner_example"
    user_data_raw        = "user_data_raw_example"
    instance = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      instance_type                = "instance_type_example"
      key_name                     = "key_name_example"
      metadata_endpoint_enabled    = "enabled"
      metadata_options_http_tokens = "required"
      monitoring                   = true
      ebs_block_device_inline      = false
      vpc_security_group_ids       = []
      private_dns_name_options = {
        enable_resource_name_dns_aaaa_record = false
        enable_resource_name_dns_a_record    = false
        hostname_type                        = "hostname_type_example"
      }
    }
    ebs_volume_config = {
      "vol1" = {
        iops       = 1000
        throughput = 100
        total_size = 100
        type       = "type_example"
        kms_key_id = "kms_key_id_example"
      },
      "vol2" = {
        iops       = 1000
        throughput = 100
        total_size = 100
        type       = "type_example"
        kms_key_id = "kms_key_id_example"
      },
    }
    ebs_volumes = {
      "vol1" = {
        label       = "label_example"
        snapshot_id = "snapshot_id_example"
        iops        = 1000
        throughput  = 100
        size        = 100
        type        = "type_example"
        kms_key_id  = "kms_key_id_example"
      },
      "vol2" = {
        label       = "label_example"
        snapshot_id = "snapshot_id_example"
        iops        = 1000
        throughput  = 100
        size        = 100
        type        = "type_example"
        kms_key_id  = "kms_key_id_example"
      },
    }
    route53_records = {
      create_internal_record = false
      create_external_record = false
    }
  }
}

variable "tags" {
  type = any
}