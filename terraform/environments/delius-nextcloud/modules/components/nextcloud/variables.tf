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
variable "nextcloud_passwordsalt"{
  type = string

}

variable "nextcloud_secret"{
  type = string
}

variable "app_name"{
  type = string
}

variable "external_domain"{
  type = string
}

variable "cidr_block_a"{
  type = string
}

variable "cidr_block_b"{
  type = string
}

variable "cidr_block_c"{
  type = string
}

variable "internal_domain"{
  type = string
}

variable "nextcloud_dbuser"{
  type = string
}

variable "nextcloud_dbpassword"{
  type = string
}

variable "nextcloud_id"{
  type = string
}

variable "env_type"{
  type = string
}

variable "pwm_url"{
  type = string
}

variable "strategic_pwm_url"{
  type = string
}

variable "redis_host"{
  type = string
}

variable "redis_port"{
  type = string
}

variable "mail_server"{
  type = string
}

variable "from_address"{
  type = string
}

