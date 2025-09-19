variable "db_type" {
  description = "Database type: [primary, secondary]"
  default     = "primary"
  type        = string
}

variable "db_suffix" {
  description = "identifier to append to name e.g. dsd, boe"
  type        = string
  default     = "db"
}

variable "deploy_oracle_stats" {
  description = "for deploying Oracle stats bucket"
  default     = true
  type        = bool
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

variable "server_type_tag" {
  description = "tag to set on each instance for key `server_type`"
  type        = string
  default     = "delius_core_db"
}

variable "database_tag_prefix" {
  description = "tag to set on each instance for key `database`"
  type        = string
  default     = "delius"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone to launch the instance in"
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

variable "account_info" {
  description = "Account info to pass to the instance"
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
    owner      = string
  })

}

variable "tags" {
  description = "Tags to apply to the instance"
  type        = map(string)
}

variable "ebs_volumes" {
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

variable "ebs_volume_config" {
  description = "EC2 volume configurations, where key is a label, e.g. flash, which is assigned to the disk in ebs_volumes.  All disks with same label have the same configuration.  If not specified, use values from the AMI.  If total_size specified, the volume size is this divided by the number of drives with the given label"
  type = map(object({
    iops       = optional(number)
    throughput = optional(number)
    total_size = optional(number)
    type       = optional(string)
    kms_key_id = optional(string)
  }))
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

variable "security_group_ids" {
  description = "A list of security group IDs to attach"
  type        = list(string)
}

variable "ssh_keys_bucket_name" {
  description = "The name of the S3 bucket containing the SSH keys"
  type        = string
}

variable "user_data_replace_on_change" {
  description = "Whether to replace the instances when the user data changes"
  type        = bool
  default     = false
}

variable "instance_profile_policies" {
  description = "A list of IAM policy ARNs to attach to the instance profile"
  type        = list(string)
}

variable "enable_platform_backups" {
  description = "Enable or disable Mod Platform centralised backups"
  type        = bool
  default     = null
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic"
  type        = string
}

variable "inline_ebs" {
  default     = false
  type        = bool
  description = "Whether to create EBS volumes inline with the instance"
}

variable "enable_cloudwatch_alarms" {
  description = "Enable or disable CloudWatch metric alarms for the instance"
  type        = bool
  default     = true
}

