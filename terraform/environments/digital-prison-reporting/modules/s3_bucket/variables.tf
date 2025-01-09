
variable "name" {
  description = "Name of the Bucket"
  type        = string
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
  type        = string
  default     = "s3-notification-event"
}

variable "create_s3" {
  description = "Setup S3 Buckets"
  type        = bool
  default     = false
}

variable "custom_kms_key" {
  type        = string
  description = "KMS key ARN to use"
  default     = ""
}

variable "create_notification_queue" {
  description = "Setup Notification Queue"
  type        = bool
  default     = false
}

variable "sqs_msg_retention_seconds" {
  description = "SQS Message Retention"
  type        = number
  default     = 86400
}

variable "filter_prefix" {
  description = "S3 Notification Filter Prefix"
  type        = string
  default     = null
}

variable "enable_lifecycle" {
  description = "Enabled Lifecycle for S3 Storage, Default is False"
  type        = bool
  default     = false
}

variable "enable_versioning_config" {
  description = "Enable Versioning Config for S3 Storage, Default is Disabled"
  type        = string
  default     = "Disabled"
}

variable "enable_s3_versioning" {
  description = "Enable Versioning for S3 Bucket, Default is false"
  type        = bool
  default     = false
}

variable "enable_notification" {
  description = "Enable S3 Bucket Notifications, Default is false"
  type        = bool
  default     = false
}

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
  type        = bool
  default     = true
}

## Dynamic override_expiration_rules
variable "override_expiration_rules" {
  type    = list(object({ id = string, prefix = string, days = number }))
  default = []
}

variable "lifecycle_category" {
  type    = string
  default = "standard" # Options: "short_term", "long_term", "temporary", "standard"
}

variable "enable_intelligent_tiering" {
  description = "Enable Intelligent-Tiering storage class for S3 bucket"
  type        = bool
  default     = false
}