variable "email_url" {
  type        = string
  nullable    = true
  sensitive   = true
  default     = null
  description = "(Optional) Digital Prison Reporting notification email url."
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