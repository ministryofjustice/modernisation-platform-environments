
variable "environment" {
  type        = string
  description = "Environment of the resources"
}

variable "application_name" {
  type        = string
  description = "Name of application"
}

variable "identifier_name" {
  type        = string
  description = "Database Identifier - Must be lowercase"
}

variable "region" {
  type        = string
  description = "Region for the RD Database"
}

variable "port" {
  type        = string
  description = "Port for the DB"
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

variable "iops" {
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

variable "performance_insights_enabled" {
  type        = string
  description = "Enable performance insights or not"
}

variable "performance_insights_retention_period" {
  type        = string
  description = "Retention period for PI. Typically longer for prod dbs"
}

variable "snapshot_arn" {
  type        = string
  description = "The ARN of the source snapshot"
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

variable "cloud_platform_cidr" {
  type        = string
  description = "transit_gateway_cidr"
}

variable "ecs_cluster_sec_group_id" {
  type        = string
  description = "ID of the ecs cluster security group allowed to access RDS"
}

variable "mlra_ecs_cluster_sec_group_id" {
  type        = string
  description = "ID of the MLRA ecs cluster security group allowed to access RDS"
}

variable "hub20_sec_group_id" {
  type        = string
  description = "ID of the HUB 2.0 security group allowed to access the RDS"
  default     = ""
}

variable "bastion_security_group_id" {
  type        = string
  description = "bastion security group id"
}

  variable "mojfin_sec_group_id" {
    type        = string
    description = "Mojfin security group id"
  }

variable "kms_key_arn" {
  type        = string
  description = "kms key arn"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "hub20_s3_bucket" {
  type        = string
  description = "HUB 2.0 S3 Bucket name"
  default     = ""
}






