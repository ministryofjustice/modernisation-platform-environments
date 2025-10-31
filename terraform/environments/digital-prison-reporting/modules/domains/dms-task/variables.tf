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

variable "name" {
  description = "DMS Replication name."
  default     = ""
}

variable "env" {
  type        = string
  description = "Env Type"
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


variable "short_name" {
  type    = string
  default = ""
}