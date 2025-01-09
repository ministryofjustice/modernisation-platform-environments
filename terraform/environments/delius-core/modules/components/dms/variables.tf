
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
  type = any
}

variable "db_suffix" {
  description = "identifier to append to name e.g. dsd, boe"
  type        = string
  default     = "db"
}

variable "database_application_passwords_secret_arn" {
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

variable "db_ec2_sg_id" {
  description = "Security group id of the database EC2 hosts"
  type        = string
}

variable "env_name_to_dms_config_map" {
  description = "Map of delius-core environments to DMS configs"
  type        = any
}

variable "oracle_db_instance_scheduling" {
  description = "instance_scheduling value.  See https://user-guide.modernisation-platform.service.justice.gov.uk/concepts/environments/instance-scheduling.html"
  type        = string
}