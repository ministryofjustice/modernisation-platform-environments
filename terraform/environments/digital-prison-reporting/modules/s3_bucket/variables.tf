
variable "name" {
  description = "Name of the Bucket"
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(any)
}

variable "s3_notification_name" {
  description = "S3 Notification Event Name"
  default     = "s3-notification-event"
}

variable "create_s3" {
  description = "Setup S3 Buckets"
  default     = false
}

variable "enable_lifecycle" {
  description = "Enabled Lifecycle for S3 Storage, Default is False"
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