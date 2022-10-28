variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "environment" {
  type        = string
  description = "Environment of the resources"
}

variable "application_name" {
  type        = string
  description = "Name of application"
}

variable "db_family" {
  type        = string
  description = "Family of the RDS database"
}

variable "db_engine" {
  type        = string
  description = "Engine for the DB Option Group"
}

variable "db_engine_version" {
  type        = string
  description = "Engine version for the DB Option Group"
}

variable "db_full_engine_version" {
  type        = string
  description = "Full engine version for the DB instance resource"
}

variable "db_subnet_ids" {
  type        = list(any)
  description = "Database subnet ids for RDS subnet group"
}

variable "db_vpc_id" {
  type        = string
  description = "Database VPC id for RDS security group"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "db_storage_type" {
  type        = string
  description = "RDS instance storage type"
}

variable "db_storage_iops" {
  type        = string
  description = "RDS instance storage type"
}

variable "db_backup_retention_period" {
  type        = string
  description = "RDS instance back up retention in days (0 - 35)"
}

variable "db_admin_username" {
  type        = string
  description = "RDS instnance admin username"
}
