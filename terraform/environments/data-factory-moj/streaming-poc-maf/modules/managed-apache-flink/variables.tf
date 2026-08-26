variable "private_subnets" {
  description = "Private subnets to use"
  type        = list(string)
}

variable "config_property_group" {
  description = "Config property group map passed to the Flink application."

  type = object({
    app_name                      = string
    log_retention_days            = optional(number, 7)
    runtime_environment           = optional(string, "FLINK-1_20")
    parallelism                   = optional(number, 2)
    parallelism_per_kpu           = optional(number, 1)
    auto_scaling_enabled          = optional(bool, false)
    log_level                     = optional(string, "INFO")
    snapshots_enabled             = optional(bool, false)
    checkpointing_type            = optional(string, "CUSTOM")
    monitoring_type               = optional(string, "CUSTOM")
    parallelism_type              = optional(string, "CUSTOM")
    checkpointing_enabled         = optional(bool, false)
    checkpoint_interval           = optional(number, 60000)
    min_pause_between_checkpoints = optional(number, 5000)
    custom_property_group         = map(string)
    job_property_group            = map(string)
    additional_iam_statements = list(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
    }))
  })
}

variable "s3_source_bucket" {
  description = "Name of the S3 bucket containing the Flink application JAR."
  type        = string
}

variable "s3_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the S3 source bucket. Required if the bucket uses customer-managed KMS encryption."
  type        = string
  default     = null
}

variable "cloudwatch_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt CloudWatch log groups."
  type        = string
  default     = null
}

variable "s3_source_key" {
  description = "S3 object key for the Flink application JAR."
  type        = string
}

variable "additional_s3_bucket_arn_list" {
  description = "List of additional S3 bucket ARNs the Flink application needs access to."
  type        = list(string)
  default     = []
}

variable "vpc_security_groups" {
  description = "List of security group IDs for the Flink application VPC configuration."
  type        = list(string)
}

variable "enable_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for the Flink application."
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms enter ALARM state."
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when alarms return to OK state."
  type        = list(string)
  default     = []
}

variable "application_failed_threshold" {
  description = "Threshold for the application failure alarm."
  type        = number
  default     = 0
}

variable "full_restarts_threshold" {
  description = "Threshold for the restart-loop alarm."
  type        = number
  default     = 0
}

variable "application_failed_period" {
  description = "Evaluation period in seconds for the application failure alarm."
  type        = number
  default     = 60
}

variable "full_restarts_period" {
  description = "Evaluation period in seconds for the restart-loop alarm."
  type        = number
  default     = 300
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
