variable "setup_additional_users" {
  description = "Boolean to determine if additional users should be set up"
  type        = bool
  default     = false
}

variable "host" {
  description = "The database host address"
  type        = string
}

variable "port" {
  description = "The database port"
  type        = number
  default     = 5432
}

variable "database" {
  description = "The database name"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
}

variable "db_master_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the main role"
  type        = string
  sensitive   = true
}

variable "readonly_privs" {
  description = "Boolean to determine if readonly privileges should be granted"
  type        = bool
  default     = true
}

variable "read_write_role" {
  description = "Boolean to determine if read-write role should be created"
  type        = bool
  default     = false
}

variable "rds_role_name" {
  description = "The name of the role to be created in the database"
  type        = string
}

variable "superuser" {
  description = "Boolean to determine if the PostgreSQL user is a superuser"
  type        = bool
  default     = false
}
