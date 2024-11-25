variable "setup_dms_endpoints" {
  description = "Enable DMS Endpoints, True or False"
  type        = bool
  default     = false
}

variable "setup_dms_iam" {
  description = "Enable DMS IAM, True or False"
  type        = bool
  default     = false
}

variable "setup_dms_source_endpoint" {
  type    = bool
  default = false
}

variable "setup_dms_s3_endpoint" {
  type    = bool
  default = false
}

variable "project_id" {
  type        = string
  description = "(Required) Project Short ID that will be used for resources."
}

variable "env" {
  type        = string
  description = "Env Type"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "extra_attributes" {
  type    = string
  default = null
}

variable "dms_source_name" {
  type    = string
  default = ""
}

variable "dms_target_name" {
  type    = string
  default = ""
}

variable "short_name" {
  type    = string
  default = ""
}

variable "source_address" {
  type        = string
  default     = ""
  description = "Default Source Address"
}

variable "source_ssl_mode" {
  default     = "none"
  description = "SSL mode to use for the connection. Valid values are none, require, verify-ca, verify-full"
  type        = string
}

variable "bucket_name" {
  type = string
}

variable "create" {
  type    = bool
  default = true
}

variable "create_iam_roles" {
  type    = bool
  default = true
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

# Used in tagginga and naming the resources

variable "stack_name" {
  type        = string
  description = "The name of our application"
  default     = "dblink"
}

variable "owner" {
  type        = string
  description = "A group email address to be used in tags"
  default     = "autobots@ga.gov.au"
}

#--------------------------------------------------------------
# DMS general config
#--------------------------------------------------------------

variable "identifier" {
  type        = string
  default     = "rds"
  description = "Name of the database in the RDS"
}

#--------------------------------------------------------------
# DMS target config
#--------------------------------------------------------------

variable "target_backup_retention_period" {
  type = string
  # Days
  default     = "30"
  description = "Retention of RDS backups"
}

variable "target_backup_window" {
  type        = string
  default     = "14:00-17:00"
  description = "RDS backup window"
}

variable "target_db_port" {
  type        = number
  description = "The port the Application Server will access the database on"
  default     = 5432
}

variable "target_engine_version" {
  type        = string
  description = "Engine version"
  default     = "9.3.14"
}

variable "target_instance_class" {
  type        = string
  default     = "db.t2.micro"
  description = "Instance class"
}

variable "target_maintenance_window" {
  type        = string
  default     = "Mon:00:00-Mon:03:00"
  description = "RDS maintenance window"
}

#variable "target_username" {
#  description = "Username to access the target database"
#}

#--------------------------------------------------------------
# DMS source config
#--------------------------------------------------------------

variable "source_app_password" {
  type        = string
  description = "Password for the endpoint to access the source database"
}

variable "source_app_username" {
  type        = string
  description = "Username for the endpoint to access the source database"
}

variable "source_db_name" {
  type        = string
  description = "Name of the Source database"
  default     = "oracle"
}

variable "source_db_port" {
  type        = number
  description = "The port the Application Server will access the database on"
  default     = null
}

variable "source_engine" {
  type        = string
  default     = "oracle-se2"
  description = "Engine type, example values mysql, postgres"
}

variable "source_engine_name" {
  type        = string
  default     = ""
  description = "Engine name for DMS"
}

variable "source_engine_version" {
  type        = string
  description = "Engine version"
  default     = "12.1.0.2.v8"
}

variable "source_instance_class" {
  type        = string
  default     = "db.t2.micro"
  description = "Instance class"
}

variable "source_maintenance_window" {
  type        = string
  default     = "Mon:00:00-Mon:03:00"
  description = "RDS maintenance window"
}

variable "source_password" {
  type        = string
  description = "Password of the source database"
  default     = ""
}

variable "source_storage_encrypted" {
  type        = bool
  description = "Encrypt storage or leave unencrypted"
  default     = false
}

variable "source_username" {
  type        = string
  description = "Username to access the source database"
  default     = ""
}

variable "postgres_source_heartbeat_frequency" {
  description = "(Optional) Sets the WAL heartbeat frequency (in minutes). Default value is 5."
  type    = number
  default = 5
}
