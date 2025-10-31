variable "name" {
  description = "The name of the file system"
  type        = string
}

variable "env_name" {
  description = "The name of the env where file system is being created"
  type        = string
}

variable "creation_token" {
  description = "A unique name used as reference when creating the Elastic File System to ensure idempotent file system creation."
  type        = string
}

variable "encrypted" {
  description = "If `true`, the disk will be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN for the KMS encryption key."
  type        = string
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s"
  type        = number
}

variable "throughput_mode" {
  description = "Throughput mode for the file system."
  type        = string
}


variable "tags" {
  description = "tags to add for all resources"
  type        = map(string)
  default = {
  }
}

variable "source_security_group_id" {
  description = "sg of source"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "subnet_ids" {
  description = "subnet ids"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "vpc cidr"
  type        = string
}

variable "enable_platform_backups" {
  description = "Enable or disable Mod Platform centralised backups"
  type        = bool
  default     = null
}

variable "account_info" {
  description = "Account info to pass to the instance"
  type        = any
}
