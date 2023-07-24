variable "glue_rule_name" {
  type        = string
  description = "(Required) Digital Prison Reporting Glue jobs status change rule name."
}

variable "glue_rule_target_name" {
  type        = string
  description = "(Required) Digital Prison Reporting Glue jobs notification target name."
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