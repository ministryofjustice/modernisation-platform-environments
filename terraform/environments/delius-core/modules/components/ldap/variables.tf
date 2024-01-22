variable "app_name" {
  description = "The name of the app"
  type        = string
}
variable "env_name" {
  description = "The name of the env where file system is being created"
  type        = string
}

variable "account_config" {
  description = "account config to pass to the instance"
  type        = any
}

variable "tags" {
  description = "tags to add for all resources"
  type        = map(string)
  default = {
  }
}

variable "account_info" {
  description = "Account info to pass to the instance"
  type        = any
}

variable "ldap_config" {
  description = "ldap config to pass to the instance"
  type        = any
}

variable "platform_vars" {
  type = object({
    environment_management = any
  })
}

variable "source_security_group_id" {
  description = "sg of source"
  type        = string
  default     = null
}

variable "environment_config" {
  description = "environment config to pass to the instance"
  type        = any
}

variable "efs_datasync_destination_arn" {
  description = "arn of the destination for datasync"
  type        = string
  default     = null
}