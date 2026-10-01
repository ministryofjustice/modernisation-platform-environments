variable "alias" {
  description = "Alias name for the KMS key, without the 'alias/' prefix."
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail permitted to use this key. Leave null to omit the CloudTrail key policy statements."
  type        = string
  default     = null
}

variable "enable_cloudwatch_logs" {
  description = "Whether to allow CloudWatch Logs to use this key for log group encryption."
  type        = bool
  default     = false
}

variable "deletion_window_in_days" {
  description = "Waiting period before the key is deleted."
  type        = number
  default     = 30
}

variable "rotation_period_in_days" {
  description = "Number of days between automatic key rotations."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
