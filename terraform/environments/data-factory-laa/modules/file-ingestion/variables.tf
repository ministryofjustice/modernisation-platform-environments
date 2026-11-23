variable "access_log_destination" {
  description = "Shared S3 access logging destination; its policy is managed by the caller."
  type = object({
    log_bucket_name = string
    log_bucket_arn  = string
  })
}

variable "kms_key_arn" {
  description = "KMS key for data lake encryption."
  type        = string
  default     = null
}

variable "database_name" {
  description = "Name of the database to use for the output"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
