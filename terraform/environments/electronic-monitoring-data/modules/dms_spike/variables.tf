variable "dms_instance_id" {
  description = "DMS id"
  type        = string
}

variable "local_tags" {
  description = "The predefined local.tags"
  type        = map(string)
}

variable "env_account_id" {
  description = "Deployment environment ID"
  type        = string
  sensitive   = true
}

variable "rds_instance_arn" {
  description = "ARN value for RDS"
  type        = string
  sensitive   = true
}

variable "dms_subnet_id" {
  description = "subnet ids for DMS subnet grop"
  type        = list(string)
}

variable "vpc_ids" {
  description = "security group for DMS"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "target s3 bucket name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "target s3 bucket arn"
  type        = string
  sensitive   = true
}

variable "table_mappings" {
  description = "Json value for table mappings"
  type        = string
}

variable "database_name" {
  description = "Target Database inside RDS"
  type        = string
  sensitive   = true
}

variable "engine_name" {
  description = "Source engine for DMS"
  type        = string
}

variable "username" {
  description = "User name for RDS"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "password for RDS"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Server name of the RDS instance"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "RDS Port value"
  type        = string
}
