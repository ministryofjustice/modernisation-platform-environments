variable "rule_name" {
  type        = string
  description = "(Required) Digital Prison Reporting rule name."
}

variable "event_pattern" {
  type        = string
  description = "(Required) Digital Prison Reporting rule event pattern."
}

variable "state" {
  type        = string
  description = "Determines the state of the rule"
  default     = "ENABLED"

  validation {
    condition     = contains(["DISABLED", "ENABLED"], var.state)
    error_message = "Accepts a value of 'DISABLED' or 'ENABLED'."
  }
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