variable "env_name" {
  type = string
}
# Account level info
variable "account_info" {
  type = any
}

variable "account_config" {
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

variable "bastion_sg_id" {
  type = string
}
