variable "name" {
  description = "Name of the EventBridge rule."
  type        = string
  default     = "eventbridge-guardduty-quarantine"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the scan alerts SNS topic."
  type        = string
}

variable "bucket_names" {
  description = "Names of the S3 buckets to apply rule to."
  type        = list(string)
  default     = []
}

variable "target_lambda_arn" {
  description = "ARN of the target Lambda function."
  type        = string
}

variable "quarantine_scan_result_statuses" {
  description = "List of scan result statuses that invoke the quarantine Lambda."
  type        = list(string)
  default     = ["THREATS_FOUND", "FAILED", "ACCESS_DENIED", "UNSUPPORTED"]
}

variable "alert_scan_result_statuses" {
  description = "List of scan result statuses to publish to the alerts topic."
  type        = list(string)
  default     = ["THREATS_FOUND", "FAILED", "ACCESS_DENIED", "UNSUPPORTED", "NO_THREATS_FOUND"]
}

variable "target_lambda_name" {
  description = "Name of the target Lambda function."
  type        = string
  default     = "quarantine-lambda"
}

# Optional tags to apply to created resources. These are merged with the standard tags applied by the module.
variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
