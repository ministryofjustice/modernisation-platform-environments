
variable "account_region" {
  type        = string
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID."
  default     = ""
}

variable "dms_source_endpoint" {
  type    = string
  default = ""
}

variable "dms_target_endpoint" {
  type    = string
  default = ""
}

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

variable "migration_type" {
  type        = string
  description = "DMS Migration Type"
  default     = ""
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
# DMS Replication Instance
#--------------------------------------------------------------

variable "replication_instance_maintenance_window" {
  type        = string
  description = "Maintenance window for the replication instance"
  default     = "sun:10:30-sun:14:30"
}

variable "replication_instance_storage" {
  type        = string
  description = "Size of the replication instance in GB"
  default     = "10"
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

variable "dms_log_retention_in_days" {
  type        = number
  default     = 14
  description = "(Optional) The default number of days log events retained in the DMS task log group."
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