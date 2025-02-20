variable "name" {
  type        = string
  description = "DMS Replication name."
}

variable "enable_replication_task" {
  description = "Enable DMS Replication Task, True or False"
  type        = bool
  default     = false
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
  type = string
}

variable "dms_target_name" {
  type = string
}

variable "short_name" {
  type = string
}

variable "migration_type" {
  type        = string
  description = "DMS Migration Type"
}

variable "subnet_ids" {
  description = "An List of VPC subnet IDs to use in the subnet group"
  type        = list(string)
  default     = []
}

variable "source_address" {
  type = string
}

variable "vpc" {
  type = string
}

variable "kinesis_stream_policy" {
  type = string
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
# DMS target config
#--------------------------------------------------------------

variable "target_engine" {
  type        = string
  default     = "kinesis"
  description = "Engine type, example values mysql, postgres"
}

variable "kinesis_settings" {
  type        = map(any)
  description = "Configuration block for Kinesis settings"
  default     = null
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
  description = "Name of the target database"
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

#--------------------------------------------------------------
# DMS Replication Instance
#--------------------------------------------------------------

variable "replication_instance_maintenance_window" {
  type        = string
  description = "Maintenance window for the replication instance"
  default     = "sun:10:30-sun:14:30"
}

variable "replication_instance_storage" {
  type        = number
  description = "Size of the replication instance in GB"
  default     = 10
}

variable "replication_instance_version" {
  type        = string
  description = "Engine version of the replication instance"
  default     = "3.4.6"
}

variable "replication_instance_class" {
  type        = string
  description = "Instance class of replication instance"
  default     = "dms.t3.micro"
}

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR for the  VPC"
  type        = list(string)
  default     = null
}

# Dummy Depends on
variable "vpc_role_dependency" {
  # the value doesn't matter; we're just using this variable
  # to propagate dependencies.
  type    = any
  default = []
}

variable "cloudwatch_role_dependency" {
  # the value doesn't matter; we're just using this variable
  # to propagate dependencies.
  type    = any
  default = []
}