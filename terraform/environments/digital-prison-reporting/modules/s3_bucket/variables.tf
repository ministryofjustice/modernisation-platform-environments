
variable "name" {
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
  description = "S3 Notification Event Name"
  default     = "s3-notification-event"
}

variable "create_s3" {
  description = "Setup S3 Buckets"
  default     = false
}

variable "custom_kms_key" {
  type        = string
  description = "KMS key ARN to use"
  default     = ""
}

variable "create_notification_queue" {
  description = "Setup Notification Queue"
  default     = false
}

variable "sqs_msg_retention_seconds" {
  description = "SQS Message Retention"
  default     = 86400
}

variable "filter_prefix" {
  description = "S3 Notification Filter Prefix"
  default     = null
}

variable "enable_lifecycle" {
  description = "Enabled Lifecycle for S3 Storage, Default is False"
  default     = false
}

variable "enable_lifecycle_expiration" {
  description = "Enable item expiration - requires 'enable_lifecycle' to be enabled."
  default     = false
}

variable "expiration_days" {
  description = "Days to wait before deleting expired items."
  default     = 90
}

variable "expiration_prefix_redshift" {
  description = "Directory Prefix where Redshift Async query results are stored to apply expiration to."
  default     = "/"
}

variable "expiration_prefix_athena" {
  description = "Directory Prefix where Athena Async query results are stored to apply expiration to."
  default     = "/"
}

variable "enable_versioning_config" {
  description = "Enable Versioning Config for S3 Storage, Default is Disabled"
  default     = "Disabled"
}

variable "enable_s3_versioning" {
  description = "Enable Versioning for S3 Bucket, Default is false"
  default     = false
}

variable "enable_notification" {
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
  description = "If Bucket Key is Enabled or Disabled"
  default     = true
}