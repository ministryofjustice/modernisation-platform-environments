variable "s3_bucket_landing" {
  type = string
  default = "call-centre-landing"
  description = "AWS S3 call centre landing bucket name"
}

variable "s3_bucket_logs" {
  type = string
  default = "call-centre-landing"
  description = "AWS S3 call centre logs bucket name"
}

variable "acl" {
  type        = string
  default     = "private"
  description = ""
}

# variable "sns_topic_arn" {
#   type        = string
#   default     = ""
#   description = "The ARN of the SNS topic for notifications."
# }

variable "versioning_enabled" {
  type        = bool
  default     = true
  description = ""
}

variable "logging_enabled" {
  type        = bool
  default     = true
  description = ""
}
