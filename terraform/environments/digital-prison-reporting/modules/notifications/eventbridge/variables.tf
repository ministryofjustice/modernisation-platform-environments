variable "rule_name" {
  type        = string
  description = "(Required) Digital Prison Reporting rule name."
}

variable "event_pattern" {
  type        = string
  description = "(Required) Digital Prison Reporting rule event pattern."
}

variable "event_target_name" {
  type        = string
  description = "(Required) Digital Prison Reporting rule target name."
}

variable "sns_topic_arn" {
  type        = string
  description = "(Required) Digital Prison Reporting SNS topic ARN."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}