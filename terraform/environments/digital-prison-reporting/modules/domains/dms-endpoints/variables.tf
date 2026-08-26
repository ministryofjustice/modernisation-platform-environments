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

variable "source_postgres_heartbeat_enable" {
  default     = true
  description = "Only used for Postgres sources. The write-ahead log (WAL) heartbeat feature mimics a dummy transaction. By doing this, it prevents idle logical replication slots from holding onto old WAL logs, which can result in storage full situations on the source."
  type        = bool
}

variable "source_postgres_heartbeat_frequency" {
  default     = 5
  description = "Only used for Postgres sources.  Sets the WAL heartbeat frequency (in minutes)."
  type        = number
}

variable "bucket_name" {
  type = string
}

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

variable "source_engine_name" {
  type        = string
  default     = ""
  description = "Engine name for DMS"
}
