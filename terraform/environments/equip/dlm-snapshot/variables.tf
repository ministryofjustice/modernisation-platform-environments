variable "environment" {
  description = "Environment name, EG. Development"
}

variable "service" {
  description = "Name of service to use this module. EG. SuperCaliFragiListic"
}

variable "state" {
  description = "State for the DLM policy. Valid values are `ENABLED` and `DISABLED`"
  default     = "ENABLED"
}

variable "tags" {
  description = "Map of tags to apply"
  type        = map(any)
}

variable "target_tags" {
  description = "Map of tags to look for in order to create a snapshot"
  default     = { Snapshot = "true" }
}