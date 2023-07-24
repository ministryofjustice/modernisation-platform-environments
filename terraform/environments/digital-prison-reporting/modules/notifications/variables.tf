variable "sns_topic_name" {
  type        = string
  description = "(Required) Digital Prison Reporting SNS notifications topic name."
}

variable "enable_slack_alerts" {
  type        = bool
  default     = false
  description = "(Optional) Enable Digital Prison Reporting Slack alerts."
}

variable "slack_email_url" {
  type        = string
  nullable    = true
  sensitive   = true
  default     = null
  description = "(Optional) Digital Prison Reporting Slack email url."
}

variable "enable_pagerduty_alerts" {
  type        = bool
  default     = false
  description = "(Optional) Enable Digital Prison Reporting PagerDuty alerts."
}

variable "pagerduty_alerts_url" {
  type        = string
  nullable    = true
  sensitive   = true
  default     = null
  description = "(Optional) Digital Prison Reporting PagerDuty alert url"
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