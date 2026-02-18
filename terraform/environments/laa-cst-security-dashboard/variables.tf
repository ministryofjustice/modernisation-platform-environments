variable "performance_insights_kms_key_id" {
  type        = string
  description = "KMS key for the performance insights"
  default     = null
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use to encrypt the volume"
  type        = string
  default     = null
}