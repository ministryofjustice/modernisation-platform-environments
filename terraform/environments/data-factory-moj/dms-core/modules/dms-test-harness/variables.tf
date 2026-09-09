variable "name" {
  description = "Base name used for resources belonging to the DMS integration-test harness."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "vpc_id" {
  description = "VPC in which the temporary PostgreSQL source is deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "subnet_ids" {
  description = "Private/data subnet IDs used by the temporary PostgreSQL RDS subnet group."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs must be supplied."
  }
}

variable "database_name" {
  description = "Database name created for the temporary PostgreSQL DMS source."
  type        = string
  default     = "dms_test"

  validation {
    condition     = length(trimspace(var.database_name)) > 0
    error_message = "database_name must not be empty."
  }
}

variable "database_username" {
  description = "Master username for the temporary PostgreSQL database. The password is managed by RDS in Secrets Manager."
  type        = string
  default     = "dms_admin"

  validation {
    condition     = length(trimspace(var.database_username)) > 0
    error_message = "database_username must not be empty."
  }
}

variable "postgres_port" {
  description = "Port exposed by the temporary PostgreSQL source."
  type        = number
  default     = 5432

  validation {
    condition     = var.postgres_port > 0 && var.postgres_port <= 65535
    error_message = "postgres_port must be between 1 and 65535."
  }
}

variable "postgres_engine_version" {
  description = "PostgreSQL major engine version used by the temporary RDS source."
  type        = string
  default     = "16"
}

variable "postgres_parameter_group_family" {
  description = "RDS parameter-group family corresponding to the PostgreSQL engine version."
  type        = string
  default     = "postgres16"
}

variable "instance_class" {
  description = "RDS instance class used by the temporary PostgreSQL source."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB for the temporary PostgreSQL source."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage > 0
    error_message = "allocated_storage must be greater than zero."
  }
}

variable "tags" {
  description = "Tags applied to resources created by the test harness."
  type        = map(string)
  default     = {}
}
