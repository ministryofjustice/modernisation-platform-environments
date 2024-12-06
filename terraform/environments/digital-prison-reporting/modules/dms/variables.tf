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
  type = string
}

variable "dms_target_name" {
  type = string
}

variable "short_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "migration_type" {
  type        = string
  description = "DMS Migration Type"
}

variable "rename_rule_source_schema" {
  description = "The source schema we will rename to a target output 'space'"
  type        = string
}

variable "rename_rule_output_space" {
  description = "The name of the target output 'space' that the source schema will be renamed to"
  type        = string
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

variable "availability_zone" {
  type    = string
  default = null
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
  type        = string
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

variable "source_backup_window" {
  type        = string
  # 12:00AM-03:00AM AEST
  default     = "14:00-17:00"
  description = "RDS backup window"
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
  default     = "dms.t2.micro"
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed"
  type        = bool
  default     = false
}

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

variable "database_subnet_cidr" {
  type        = list(string)
  default     = ["10.26.25.208/28", "10.26.25.224/28", "10.26.25.240/28"]
  description = "List of subnets to be used for databases"
}

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