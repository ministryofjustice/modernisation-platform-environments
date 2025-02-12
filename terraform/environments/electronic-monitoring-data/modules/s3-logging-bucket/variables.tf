variable "bucket_name" {
  description = "The name of the S3 bucket to create for logging"
  type        = string
}

variable "source_bucket_name" {
  description = "The name of the source S3 bucket to enable logging for"
  type        = string
}

variable "source_bucket_id" {
  description = "The id of the source S3 bucket to enable logging for"
  type        = string
}

variable "target_prefix" {
  description = "The prefix for log object keys"
  type        = string
  default     = "logs/"
}

variable "local_tags" {
  description = "The predefined local.tags"
  type        = map(string)
  default     = {}
}
