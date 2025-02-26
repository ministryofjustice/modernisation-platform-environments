variable "event_source" {
  type        = string
  description = "partner event source"
}

variable "log_group_arn" {
  type        = string
  description = "cloudwatch log group target"
}