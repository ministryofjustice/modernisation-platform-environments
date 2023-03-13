variable "environment" {
  type        = string
  description = "Environment of the resources"
}

variable "application_name" {
  type        = string
  description = "Name of application"
}

variable "region" {
  type        = string
  description = "Region for the RD Database"
}

variable "identifier_name" {
  type        = string
  description = "Database Identifier - Must be lowercase"
}

variable "engine" {
  type        = string
  description = "Engine for the DB"
}

variable "engine_version" {
  type        = string
  description = "Engine version for the DB"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "allocated_storage" {
  type        = string
  description = "Allocated Storage for the database"
}

variable "storage_type" {
  type        = string
  description = "RDS instance storage type"
}

variable "backup_retention_period" {
  type        = string
  description = "RDS instance back up retention in days (0 - 35)"
}

variable "backup_window" {
  type        = string
  description = "RDS instance back up window"
}

variable "maintenance_window" {
  type        = string
  description = "Weekly Maintenance Window required by the RDS"
}

variable "character_set_name" {
  type        = string
  description = "DB Character Set"
}

variable "availability_zone" {
  type        = string
  description = "Availability Zone"
}

variable "multi_az" {
  type        = string
  description = "Wether multi az failover is enabled or not"
}

variable "allow_major_version_upgrade" {
  type        = string
  description = "Wether auto major db upgrades are allowed"
}

variable "auto_minor_version_upgrade" {
  type        = string
  description = "Wether auto minor db upgrades are allowed"
}

variable "username" {
  type        = string
  description = "RDS instnance admin username"
}

variable "db_password_rotation_period" {
  type        = string
  description = "DB Password Rotation Period"
}

variable "license_model" {
  type        = string
  description = "Licence Type for the RDS"
}

variable "rds_snapshot_arn" {
  type        = string
  description = "RDS snapshot ARN to build database from"
}

variable "rds_kms_key_arn" {
  type        = string
  description = "KMS key to encrypt RDS"
}

variable "lz_vpc_cidr" {
  type        = string
  description = "The CIDR range of the LAA LZ"
}


variable "deletion_protection" {
  type        = string
  description = "deletion_protection"
}

variable "vpc_shared_id" {
  type        = string
  description = "vpc_shared_id"
}

variable "vpc_shared_cidr" {
  type        = string
  description = "vpc_shared_cidr"
}

variable "vpc_subnet_a_id" {
  type        = string
  description = "vpc_subnet_a_id"
}

variable "vpc_subnet_b_id" {
  type        = string
  description = "vpc_subnet_b_id"
}

variable "vpc_subnet_c_id" {
  type        = string
  description = "vpc_subnet_c_id"
}
