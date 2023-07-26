variable "sns_topic_name" {
  type        = string
  description = "(Required) Digital Prison Reporting SNS notifications topic name."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}