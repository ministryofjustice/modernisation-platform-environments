variable "identity_provider_arn" {
  type        = string
  description = "Identity provider used to trust AP Compute account"
}

variable "role_name" {
  default    = "airflow"
  type        = string
}

variable "data_buckets" {
  type        = list(string)
  description = "List of S3 buckets to grant access to"
}

#variable "kms_key_arn" {
#  type        = string
#  description = "ARN of the KMS key to use for S3 bucket encryption (if using custom KMS key)"
#  default     = null
#}
