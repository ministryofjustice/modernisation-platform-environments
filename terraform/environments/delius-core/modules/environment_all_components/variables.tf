variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

# Account level info
variable "account_info" {
  type = object({
<<<<<<< HEAD
    business_unit     = string,
    application_name  = string,
    region            = string,
    vpc_id            = string,
    mp_environment    = string
=======
    business_unit    = string,
    region           = string,
    vpc_id           = string,
    application_name = string,
    mp_environment   = string
>>>>>>> main
  })
}

#variable "ldap_migration_bucket_arn" {
#  type = string
#}

variable "network_config" {
  type = object({
    shared_vpc_cidr                = string
    private_subnet_ids             = list(string)
    route53_inner_zone_info        = any
    migration_environment_vpc_cidr = optional(string)
    general_shared_kms_key_arn      = optional(string)
  })
  default = {
    shared_vpc_cidr                = "default_shared_vpc_cidr"
    private_subnet_ids             = ["default_private_subnet_a_id"]
    route53_inner_zone_info        = {}
    migration_environment_vpc_cidr = "default_migration_environment_vpc_cidr"
    general_shared_kms_key_arn      = "default_general_shared_kms_key_arn"
  }
}

variable "ldap_config" {
  type = object({
<<<<<<< HEAD
    name                 = string
  })
  default = {
    name                 = "default_name"
=======
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
>>>>>>> main
  }
}

#variable "db_config" {
#  type = object({
#    name                 = string
#    ami_name             = string
#    ami_owner            = string
#    user_data_raw        = string
#  })
#  default = {
#    name                 = "default_name"
#    ami_name             = "default_ami_name"
#    ami_owner            = "default_ami_owner"
#    user_data_raw        = null
#  }
#}

variable "db_config" {
  type = list(object({
    name                 = string
<<<<<<< HEAD
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
    tags = map(any)
  }))
}

#variable "db_config_instance" {
#  description = "EC2 instance settings, see aws_instance documentation"
#  type = object({
#    associate_public_ip_address  = optional(bool, false)
#    disable_api_termination      = bool
#    instance_type                = string
#    key_name                     = string
#    metadata_endpoint_enabled    = optional(string, "enabled")
#    metadata_options_http_tokens = optional(string, "required")
#    monitoring                   = optional(bool, true)
#    ebs_block_device_inline      = optional(bool, false)
#    vpc_security_group_ids       = list(string)
#    private_dns_name_options = optional(object({
#      enable_resource_name_dns_aaaa_record = optional(bool)
#      enable_resource_name_dns_a_record    = optional(bool)
#      hostname_type                        = string
#    }))
#  })
#}
#
#variable "db_config_ebs_volume_config" {
#  description = "EC2 volume configurations, where key is a label, e.g. flash, which is assigned to the disk in ebs_volumes.  All disks with same label have the same configuration.  If not specified, use values from the AMI.  If total_size specified, the volume size is this divided by the number of drives with the given label"
#  type = map(object({
#    iops       = optional(number)
#    throughput = optional(number)
#    total_size = optional(number)
#    type       = optional(string)
#    kms_key_id = optional(string)
#  }))
#}
#
#variable "db_config_ebs_volumes" {
#  description = "EC2 volumes, see aws_ebs_volume for documentation.  key=volume name, value=ebs_volume_config key.  label is used as part of the Name tag"
#  type = map(object({
#    label       = optional(string)
#    snapshot_id = optional(string)
#    iops        = optional(number)
#    throughput  = optional(number)
#    size        = optional(number)
#    type        = optional(string)
#    kms_key_id  = optional(string)
#  }))
#}
#
#variable "db_config_route53_records" {
#  description = "Optionally create internal and external DNS records"
#  type = object({
#    create_internal_record = bool
#    create_external_record = bool
#  })
#}

variable "subnet_id" {
  type = string
}

variable "aws_kms_key_general_shared_arn" {
  type = string
}

#variable "db_config_tags" {
#  type        = map(any)
#  description = "Default tags to be applied to resources.  Additional tags can be added to EBS volumes or EC2s, see instance.tags and ebs_volume_tags variables."
#}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources.  Additional tags can be added to EBS volumes or EC2s, see instance.tags and ebs_volume_tags variables."
=======
  })
  default = {
    name                 = "default_name"
  }
>>>>>>> main
}

variable "tags" {
  type = any
}