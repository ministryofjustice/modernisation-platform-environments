variable "environment" {
  description = "Environment name, EG. Development"
  type        = string
}

variable "service" {
  description = "Name of service to use this module. EG. SuperCaliFragiListic"
  type        = string
}

variable "state" {
  description = "State for the DLM policy. Valid values are `ENABLED` and `DISABLED`"
  type        = string
  default     = "ENABLED"
}

variable "tags" {
  description = "Map of tags to apply"
  type        = map(any)
}

variable "target_tags" {
  description = "Map of tags to look for in order to create a snapshot"
  type        = map(string)
  default     = { Snapshot = "true" }
}