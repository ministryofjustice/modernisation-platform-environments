variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "bucket_prefix" {
  description = "Prefix for the logging bucket."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for the logging bucket and CloudTrail encryption."
  type        = string
}

variable "cloudwatch_log_retention_in_days" {
  description = "Number of days to retain CloudWatch logs."
  type        = number
  default     = 365
}