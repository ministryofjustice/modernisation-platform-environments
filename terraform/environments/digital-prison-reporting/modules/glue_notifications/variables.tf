variable "rule_name" {
  type        = string
  description = "(Required) Glue jobs status change rule name."
}

variable "target_name" {
  type        = string
  description = "(Required) Glue jobs notification target name."
}

variable "sns_topic_name" {
  type        = string
  description = "(Required) Glue jobs notification SNS topic name."
}

variable "enable_slack_alerts" {
  type        = bool
  default     = false
  description = "(Optional) Enable Slack alerts."
}

variable "slack_email_url" {
  type        = string
  nullable    = true
  sensitive   = true
  default     = null
  description = "(Optional) Slack email url."
}

variable "enable_pagerduty_alerts" {
  type        = bool
  default     = false
  description = "(Optional) Enable PagerDuty alerts."
}

variable "pagerduty_alerts_url" {
  type        = string
  nullable    = true
  sensitive   = true
  default     = null
  description = "(Optional) PagerDuty alert url"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "region" {
  default     = "eu-west-2"
  description = "(Optional) Current AWS Region."
}