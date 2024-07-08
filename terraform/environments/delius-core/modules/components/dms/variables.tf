
variable "account_config" {
  description = "Account config to pass to the instance"
  type        = any
}

variable "account_info" {
  description = "Account info to pass to the instance"
  type        = any
}

variable "replication_instance_class" {
  description = "instance class to use for dms"
  type        = string
  default     = "dms.t3.micro"
}

variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}

variable "tags" {
  description = "tags to add for all resources"
  type        = map(string)
  default = {
  }
}

variable "engine_version" {
  description = "instance version to use for dms"
  type        = string
  default     = "3.5.1"
}

variable "dms_config" {
  type = object({
    replication_instance_class = string
    engine_version             = string
  })
}

variable "db_suffix" {
  description = "identifier to append to name e.g. dsd, boe"
  type        = string
  default     = "db"
}

variable "delius_core_application_passwords_arn" {
  type = any
}

variable "oracle_db_server_names" {
  type = object({
    primarydb  = string
    standbydb1 = string
    standbydb2 = string
  })
}

variable "platform_vars" {
  type = object({
    environment_management = any
  })
}

}