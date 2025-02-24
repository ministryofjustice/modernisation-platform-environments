variable "name" {
  description = "DMS Replication name."
  type        = string
  default     = ""
}

variable "setup_dms_instance" {
  description = "Enable DMS Instance, True or False"
  type        = bool
  default     = false
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

variable "subnet_ids" {
  description = "An List of VPC subnet IDs to use in the subnet group"
  type        = list(string)
  default     = []
}

variable "vpc" {
  type    = string
  default = ""
}

variable "availability_zone" {
  type    = string
  default = null
}

variable "create" {
  type    = bool
  default = true
}

#--------------------------------------------------------------
# DMS Replication Instance
#--------------------------------------------------------------

variable "replication_instance_maintenance_window" {
  description = "Maintenance window for the replication instance"
  type        = string
  default     = "sun:10:30-sun:14:30"
}

variable "replication_instance_storage" {
  description = "Size of the replication instance in GB"
  type        = string
  default     = "10"
}

variable "replication_instance_version" {
  description = "Engine version of the replication instance"
  type        = string
  default     = "3.4.6"
}

variable "replication_instance_class" {
  description = "Instance class of replication instance"
  type        = string
  default     = "dms.t3.micro"
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed"
  type        = bool
  default     = false
}

variable "dms_log_retention_in_days" {
  type        = number
  default     = 14
  description = "(Optional) The default number of days log events retained in the DMS task log group."
}

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR for the  VPC"
  type        = list(string)
  default     = null
}

#--------------------------------------------------------------
# DMS Task
#--------------------------------------------------------------
variable "table_mappings" {
  type    = any
  default = ""
}

variable "replication_task_settings" {
  type    = any
  default = {}
}

variable "rename_rule_source_schema" {
  description = "The source schema we will rename to a target output 'space'"
  type        = string
  default     = ""
}

variable "rename_rule_output_space" {
  description = "The name of the target output 'space' that the source schema will be renamed to"
  type        = string
  default     = ""
}


variable "enable_replication_task" {
  description = "Enable DMS Replication Task, True or False"
  type        = bool
  default     = false
}

variable "migration_type" {
  type        = string
  description = "DMS Migration Type"
  default     = ""
}

variable "dms_replication_instance" {
  type        = string
  default     = ""
  description = "DMS Rep Instance ARN"
}

variable "dms_source_endpoint" {
  type    = string
  default = ""
}

variable "dms_target_endpoint" {
  type    = string
  default = ""
}

#--------------------------------------------------------------
# DMS Endpoint
#--------------------------------------------------------------

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

variable "extra_attributes" {
  type    = string
  default = null
}

variable "source_db_name" {
  description = "Name of the Source database"
  type        = string
  default     = "oracle"
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
  default     = ""
  description = "Default Source Address"
  type        = string
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
  type    = string
  default = ""
}


variable "source_db_port" {
  description = "The port the Application Server will access the database on"
  type        = number
  default     = null
}

variable "source_engine_name" {
  default     = ""
  type        = string
  description = "Type of engine for the source endpoint. Example valid values are postgres, oracle"
}


variable "source_app_password" {
  description = "Password for the endpoint to access the source database"
  type        = string
  default     = ""
}

variable "source_app_username" {
  description = "Username for the endpoint to access the source database"
  type        = string
  default     = ""
}
