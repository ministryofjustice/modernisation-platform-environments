
variable "account_region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account_id" {
  description = "AWS Account ID."
  default     = ""
}

variable "dms_source_endpoint" {
  type        = string
  default     = ""
}

variable "dms_target_endpoint" {
  type        = string
  default     = ""
}

variable "name" {
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
  default = ""
}

variable "dms_target_name" {
  type = string
  default = ""
}

variable "short_name" {
  type = string
  default = ""
}

variable "migration_type" {
  type        = string
  description = "DMS Migration Type"
  default     = ""
}

variable "availability_zones" {
  default = [
    {
      0 = "eu-west-2a"
    }
  ]
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
  type        = string
  default     = ""  
}

variable "availability_zone" {
  default = null
}

variable "create" {
  default = true
}

variable "create_iam_roles" {
  default = true
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

# Used in tagginga and naming the resources

variable "stack_name" {
  description = "The name of our application"
  default     = "dblink"
}

variable "owner" {
  description = "A group email address to be used in tags"
  default     = "autobots@ga.gov.au"
}

#--------------------------------------------------------------
# DMS general config
#--------------------------------------------------------------

variable "identifier" {
  default     = "rds"
  description = "Name of the database in the RDS"
}

