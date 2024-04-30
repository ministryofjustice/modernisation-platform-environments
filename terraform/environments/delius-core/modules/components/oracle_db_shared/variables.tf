variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}


variable "tags" {
  description = "Tags to apply to the instance"
  type        = map(string)
}

variable "environment_config" {
  type = any
}

variable "account_config" {
  description = "Account config to pass to the instance"
  type        = any
}

variable "account_info" {
  description = "Account info to pass to the instance"
  type        = any
}

variable "platform_vars" {
  description = "Platform vars to pass to the instance"
  type        = any
}

variable "public_keys" {
  description = "Public keys to add to the instance"
  type        = map(any)
}

variable "bastion_sg_id" {
  description = "Security group id of the bastion"
  type        = string
}

variable "deploy_oracle_stats" {
  description = "for deploying Oracle stats bucket"
  default     = true
  type        = bool
}

variable "db_suffix" {
  description = "identifier to append to name e.g. dsd, boe"
  type        = string
  default     = "db"
}
