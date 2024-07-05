variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

# Account level info
variable "account_info" {
  type = any
}

variable "account_config" {
  type = any
}

variable "environment_config" {
  type = any
}

variable "bastion_config" {
  type = any
}

variable "nextcloud_config" {
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

variable "environments_in_account" {
  type    = list(string)
  default = []
}

variable "pagerduty_integration_key" {
  description = "Pager Duty Integration Key"
  type        = string
  default     = null
}
