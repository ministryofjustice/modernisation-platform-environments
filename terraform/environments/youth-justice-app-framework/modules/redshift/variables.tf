variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "database_subnets" {
  description = "List of database subnets"
  type        = list(string)
}

## 
variable "rds_secret_rotation_arn" {
  description = "The ARN of the rotated postgres secret."
  type        = string
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the AWS KMS key to be used to encrypt redshift data and the secret values in the versions stored by this module."
}

variable "postgres_security_group_id" {
  type        = string
  description = "The ID of the Security group that represents the PostgreSQL instance which required access to Redshift."
}

variable "data_science_role" {
  type = string
  description = "The arn of a role that is adpopted by YJB Data Scientests."
  default = null #"arn:aws:iam::066012302209:role/data_science"
}