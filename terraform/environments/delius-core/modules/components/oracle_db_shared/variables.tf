variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}


variable "tags" {
  description = "Tags to apply to the instance"
  type        = map(string)
}

variable "environment_config" {
  type = object({
    migration_environment_private_cidr = optional(list(string))
    migration_environment_db_cidr      = optional(list(string))
    legacy_engineering_vpc_cidr        = string
    ec2_user_ssh_key                   = string
  })
}

variable "account_config" {
  description = "Account config to pass to the instance"
  type        = any
}


variable "public_keys" {
  description = "Public keys to add to the instance"
  type        = map(any)
}