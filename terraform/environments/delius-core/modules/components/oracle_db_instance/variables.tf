variable "db_type" {
  description = "Database type: [primary, secondary]"
  default     = "primary"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "r6i.xlarge"
}

variable "db_count_index" {
  description = "Database count index"
  type        = number
  default     = 1
}

variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

variable "monitoring" {
  description = "Enable/disable detailed monitoring"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "User data to pass to the instance"
  type        = string
}

variable "account_config" {
  description = "Account config to pass to the instance"
  type        = any
}

variable "metadata_options" {
  description = "Metadata options to pass to the instance"
  type = object({
    http_endpoint = string
    http_tokens   = string
  })
  default = {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }
}

variable "db_ami" {
  description = "AMI to use for the database instance"
  type = object({
    name_regex = string
    owners     = list(string)
  })

}

variable "tags" {
  description = "Tags to apply to the instance"
  type        = map(string)
}

variable "ebs_volumes" {
  description = "EBS volumes to attach to the instance"
  type = object({
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
  })
}

variable "environment_config" {
  type = object({
    migration_environment_private_cidr = optional(list(string))
    migration_environment_db_cidr      = optional(list(string))
    legacy_engineering_vpc_cidr        = string
    ec2_user_ssh_key                   = string
  })
}

variable "ec2_key_pair_name" {
  description = "EC2 key pair name to associate with the instance"
  type        = string
}

variable "standby_dbs_required" {
  description = "Number of standby databases required"
  type        = number
  default     = 0
}

variable "instance_profile" {
  description = "The instance profile to attach"
  type        = any
}

variable "security_group_ids" {
  description = "A list of security group IDs to attach"
  type        = list(string)
}
