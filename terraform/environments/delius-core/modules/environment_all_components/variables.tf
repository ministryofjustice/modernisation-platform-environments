variable "name" {
  type = string
}

# Account level info
variable "account_info" {
  type = object({
    business_unit     = string,
    application_name  = string,
    region            = string,
    vpc_id            = string,
    mp_environment    = string
  })
}

variable "ldap_config" {
  type = object({
    name                 = string
    some_other_attribute = optional(string)
  })
  default = {
    name                 = "default_name"
    some_other_attribute = "default_some_other_attribute"
  }

}

variable "db_config" {
  type = object({
    name                 = string
    ami_name             = string
    ami_owner            = string
    user_data_raw        = string
    some_other_attribute = optional(string)
  })
  default = {
    name                 = "default_name"
    ami_name             = "default_ami_name"
    ami_owner            = "default_ami_owner"
    user_data_raw        = null
    some_other_attribute = "default_some_other_attribute"
  }
}

variable "db_config_instance" {
  description = "EC2 instance settings, see aws_instance documentation"
  type = object({
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
}

variable "db_config_ebs_volume_config" {
  description = "EC2 volume configurations, where key is a label, e.g. flash, which is assigned to the disk in ebs_volumes.  All disks with same label have the same configuration.  If not specified, use values from the AMI.  If total_size specified, the volume size is this divided by the number of drives with the given label"
  type = map(object({
    iops       = optional(number)
    throughput = optional(number)
    total_size = optional(number)
    type       = optional(string)
    kms_key_id = optional(string)
  }))
}

variable "db_config_ebs_volumes" {
  description = "EC2 volumes, see aws_ebs_volume for documentation.  key=volume name, value=ebs_volume_config key.  label is used as part of the Name tag"
  type = map(object({
    label       = optional(string)
    snapshot_id = optional(string)
    iops        = optional(number)
    throughput  = optional(number)
    size        = optional(number)
    type        = optional(string)
    kms_key_id  = optional(string)
  }))
}

variable "db_config_route53_records" {
  description = "Optionally create internal and external DNS records"
  type = object({
    create_internal_record = bool
    create_external_record = bool
  })
}

variable "subnet_id" {
  type = string
}

variable "aws_kms_key_general_shared_arn" {
  type = string
}

variable "db_config_tags" {
  type        = map(any)
  description = "Default tags to be applied to resources.  Additional tags can be added to EBS volumes or EC2s, see instance.tags and ebs_volume_tags variables."
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources.  Additional tags can be added to EBS volumes or EC2s, see instance.tags and ebs_volume_tags variables."
}
