variable "db_type" {
  description = "Database type: [primary, secondary]"
  default     = "primary"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_count_index0" {
  description = "Database count index"
  type        = number
  default     = 0
}

variable "db_count_index" {
  description = "Database count index + 1"
  type        = number
  default     = 1
}

variable "db_ami" {
  description = "AMI to use for the database instance"
  type        = string
}

variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to launch the instance in"
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
  type        = map(any)
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

variable "tags" {
  description = "Tags to apply to the instance"
  type        = map(string)
}

variable "ebs_volumes" {
  description = "EBS volumes to attach to the instance"
  type = optional(object({
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
}