variable "name" {
  description = "Base name used for resources belonging to the Oracle DMS integration-test harness."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "vpc_id" {
  description = "VPC in which the temporary Oracle source is deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "subnet_ids" {
  description = "Private data subnet IDs used by the temporary Oracle RDS subnet group and setup Lambda."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs must be supplied."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for the Oracle DMS secret, Lambda environment and S3 target."
  type        = string

  validation {
    condition     = length(trimspace(var.kms_key_arn)) > 0
    error_message = "kms_key_arn must not be empty."
  }
}

variable "rds_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the temporary Oracle RDS instance."
  type        = string

  validation {
    condition     = length(trimspace(var.rds_kms_key_arn)) > 0
    error_message = "rds_kms_key_arn must not be empty."
  }
}

variable "seed_image_uri" {
  description = "ECR image URI used by the Oracle database setup and mutation Lambda."
  type        = string

  validation {
    condition     = length(trimspace(var.seed_image_uri)) > 0
    error_message = "seed_image_uri must not be empty."
  }
}

variable "database_name" {
  description = "Database name created for the temporary Oracle DMS source."
  type        = string
  default     = "DMSTEST"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{0,7}$", var.database_name))
    error_message = "database_name must begin with a letter and contain between 1 and 8 alphanumeric characters."
  }
}

variable "database_username" {
  description = "Master username for the temporary Oracle database. The password is managed by RDS in Secrets Manager."
  type        = string
  default     = "dms_admin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,29}$", var.database_username))
    error_message = "database_username must begin with a letter and contain no more than 30 alphanumeric or underscore characters."
  }
}

variable "dms_username" {
  description = "Username created in Oracle for AWS DMS source access."
  type        = string
  default     = "DMS_USER"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,29}$", var.dms_username))
    error_message = "dms_username must begin with a letter and contain no more than 30 alphanumeric or underscore characters."
  }
}

variable "oracle_port" {
  description = "Port exposed by the temporary Oracle source."
  type        = number
  default     = 1521

  validation {
    condition     = var.oracle_port > 0 && var.oracle_port <= 65535
    error_message = "oracle_port must be between 1 and 65535."
  }
}

variable "oracle_engine_version" {
  description = "Oracle major engine version used by the temporary RDS source."
  type        = string
  default     = "19"
}

variable "oracle_parameter_group_family" {
  description = "RDS parameter-group family corresponding to the Oracle engine version."
  type        = string
  default     = "oracle-se2-19"
}

variable "instance_class" {
  description = "RDS instance class used by the temporary Oracle source."
  type        = string
  default     = "db.m5.large"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB for the temporary Oracle source."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage > 0
    error_message = "allocated_storage must be greater than zero."
  }
}

variable "max_allocated_storage" {
  description = "Maximum Oracle storage in GiB. Set to zero to disable storage autoscaling."
  type        = number
  default     = 0

  validation {
    condition     = var.max_allocated_storage >= 0
    error_message = "max_allocated_storage must be zero or greater."
  }
}

variable "archive_log_retention_hours" {
  description = "Number of hours that the Oracle test source retains archived redo logs for CDC."
  type        = number
  default     = 24

  validation {
    condition     = var.archive_log_retention_hours > 0
    error_message = "archive_log_retention_hours must be greater than zero."
  }
}

variable "tags" {
  description = "Tags applied to resources created by the Oracle test harness."
  type        = map(string)
  default     = {}
}
