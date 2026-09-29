variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "upload_bucket" {
  description = "Existing Managed File Transfer upload bucket details"
  type = object({
    arn         = string
    kms_key_arn = string
    name        = string
  })
}

variable "alarm_topic_arns" {
  description = "Existing Managed File Transfer alarm topic ARNs"
  type = object({
    high_priority = optional(string)
    low_priority  = optional(string)
  })
  default = {}
}

variable "tags" {
  description = "Tags applied to application resources"
  type        = map(string)
}