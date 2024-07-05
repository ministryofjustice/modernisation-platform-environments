variable "bytes_scanned_cutoff_per_query" {
  type        = number
  description = "Integer for the upper data usage limit (cutoff) for the amount of bytes a single query in a workgroup is allowed to scan. Must be at least 10485760."
  default     = -1
}
variable "description" {
  type        = string
  description = "The description of the workgroup.  Defaults to \"The workgroup for [NAME].\""
  default     = ""
}

variable "state_enabled" {
  type        = bool
  description = "Whether the workgroup is enabled."
  default     = true
}

variable "setup_athena_workgroup" {
  type        = bool
  description = "Whether the workgroup to be Setup."
  default     = true
}

variable "enforce_workgroup_configuration" {
  type        = bool
  description = "Boolean whether the settings for the workgroup override client-side settings."
  default     = true
}

variable "encryption_option" {
  type        = string
  description = "Indicates type of encryption used, either SSE_S3, SSE_KMS, or CSE_KMS."
  default     = "SSE_S3"
}

variable "kms_key_arn" {
  type        = string
  description = " For SSE_KMS and CSE_KMS, this is the KMS key Amazon Resource Name (ARN)."
  default     = ""
}

variable "name" {
  type        = string
  description = "The name of the AWS IAM policy."
}

variable "output_location" {
  type        = string
  description = "The location in Amazon S3 where your query results are stored, such as s3://path/to/query/bucket/."
}

variable "publish_cloudwatch_metrics_enabled" {
  type        = bool
  description = "Boolean whether Amazon CloudWatch metrics are enabled for the workgroup."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the workgroup."
  default     = {}
}