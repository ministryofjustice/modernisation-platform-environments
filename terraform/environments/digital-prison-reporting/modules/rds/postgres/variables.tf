variable "tags" {
  type    = map(any)
  default = {}
}

variable "subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "db_name" {
  type        = string
  description = "RDS Identifier"
}

variable "engine" {
  type = string
  description = "RDS Engine"
  default = "postgres"
}

variable "engine_version" {
  type        = string
  description = "RDS Engine Version"
  default     = null
}

variable "license_model" {
  type        = string
  description = "License Model"
  default     = null
}

variable "backup_window" {
  type        = string
  description = "Backup window"
  default     = "03:00-06:00"
}

variable "maintenance_window" {
  type        = string
  description = "Maintenance window"
  default     = "Mon:00:00-Mon:03:00"
}

variable "back_up_period" {
  type        = number
  description = "backup period"
  default     = 1
}

variable "parameter_group" {
  type        = string
  description = "Parameter_group"
}

variable "storage_type" {
  type        = string
  description = "Storage Type"
}

variable "db_instance_class" {
  type        = string
  description = "DB Instance Class"
}

variable "name" {
  type        = string
  description = "Rds DB Name"
  default     = "dpr-postgres-rds"
}


variable "kms" {
  type        = string
  description = "KMS Key ID for RDS Postgres"
  default     = ""
}

variable "allocated_size" {
  type        = string
  description = "Allocated Storage"
  default     = "10"
}

variable "ca_cert_identifier" {
  description = "The identifier of the CA certificate for the DB instance"
  type        = string
  default     = null
}

variable "max_allocated_size" {
  type        = string
  description = "Max Allocated Storage"
  default     = "50"
}

variable "enable_rds" {
  type        = bool
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources"
  default     = false
}

variable "master_user" {
  type        = string
  description = "Default Super User,"
  default     = "domain_builder"
}

variable "create_rds_replica" {
  type        = bool
  description = "Whether to create the RDS replica. Set to `false` to prevent the RDS replica from being created"
  default     = false
}