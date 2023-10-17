variable "backup_policy_name" {
  type        = string
  description = "S3 bucket name"
  default     = null
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
}