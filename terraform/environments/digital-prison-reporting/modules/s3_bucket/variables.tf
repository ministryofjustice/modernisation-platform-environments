
variable "name" {
  type        = string
  description = "Name of the Bucket"
  default     = ""
}

variable "project_id" {
  type        = string
  description = "Project ID"
  default     = "dpr"
}


variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(any)
}

variable "cloudtrail_access_policy" {
  type        = bool
  description = "Add CloudTrail Access Policy or Not"
  default     = false
}

variable "s3_notification_name" {
  type        = string
  description = "S3 Notification Event Name"
  default     = "s3-notification-event"
}

variable "create_s3" {
  type        = bool
  description = "Setup S3 Buckets"
  default     = false
}

variable "custom_kms_key" {
  type        = string
  description = "KMS key ARN to use"
  default     = ""
}

variable "create_notification_queue" {
  type        = bool
  description = "Setup Notification Queue"
  default     = false
}

variable "sqs_msg_retention_seconds" {
  type        = number
  description = "SQS Message Retention"
  default     = 86400
}

variable "filter_prefix" {
  type        = string
  description = "S3 Notification Filter Prefix"
  default     = null
}

variable "enable_lifecycle" {
  type        = bool
  description = "Enabled Lifecycle for S3 Storage, Default is False"
  default     = false
}

#variable "expiration_days" {
#  description = "Days to wait before deleting expired items."
#  default     = 90
#}

#variable "expiration_prefix_redshift" {
#  description = "Directory Prefix where Redshift Async query results are stored to apply expiration to."
#  default     = "/"
#}

#variable "expiration_prefix_athena" {
#  description = "Directory Prefix where Athena Async query results are stored to apply expiration to."
#  default     = "/"
#}

variable "enable_versioning_config" {
  type        = string
  description = "Enable Versioning Config for S3 Storage, Default is Disabled"
  default     = "Disabled"
}

variable "enable_s3_versioning" {
  type        = bool
  description = "Enable Versioning for S3 Bucket, Default is false"
  default     = false
}

variable "enable_notification" {
  type        = bool
  description = "Enable S3 Bucket Notifications, Default is false"
  default     = false
}

#variable "bucket_notifications" {
#  type        = map(any)
#  description = "AWS S3 Bucket Notifications"
#  default     = null
#}

variable "bucket_notifications" {
  type        = any
  description = "AWS S3 Bucket Notifications"
  default = {
    lambda_function_arn = null,
    events              = [],
    filter_prefix       = null,
    filter_suffix       = null
  }
}

variable "dependency_lambda" {
  type    = any
  default = []
}

variable "bucket_key" {
  type        = bool
  description = "If Bucket Key is Enabled or Disabled"
  default     = true
}

## Dynamic override_expiration_rules
variable "override_expiration_rules" {
  type    = list(object({ prefix = string, days = number }))
  default = []
}

variable "lifecycle_category" {
  type    = string
  default = "long_term" # Options: "short_term", "long_term", "temporary"
}

variable "enable_lifecycle_expiration" {
  type        = bool
  description = "Enable item expiration - requires 'enable_lifecycle' and 'override_expiration_rules' to be defined/enabled."
  default     = false
}