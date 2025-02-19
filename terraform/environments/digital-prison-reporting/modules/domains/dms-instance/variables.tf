variable "name" {
  type        = string
  description = "DMS Replication name."
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

variable "short_name" {
  type    = string
  default = ""
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

#--------------------------------------------------------------
# DMS Replication Instance
#--------------------------------------------------------------

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