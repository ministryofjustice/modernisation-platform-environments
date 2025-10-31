variable "enable_lambda" {
  type        = bool
  default     = false
  description = "(Optional) Create Lambda, If Set to Yes"
}

variable "image_uri" {
  description = "The URI to pull the image from"
  type        = string
}

variable "log_retention_in_days" {
  description = "Log retention in number of days."
  type        = number
  default     = 7
}

variable "memory_size" {
  description = "Amount of memory to allocate to the lambda function."
  type        = number
  default     = 2048
}

variable "ephemeral_storage_size" {
  description = "Lambda Function Ephemeral Storage in /tmp. Min 512 MB and the Max 10240 MB"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Value for the max number of seconds the lambda function will run."
  type        = number
  default     = 20
}

variable "name" {
  description = "(Required) Name of the service"
  type        = string
}

variable "tracing" {
  description = "Enable Tracing on Lambda"
  type        = string
}

variable "policies" {
  description = "Additional IAM policies to attach to the lambda's IAM role."
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to the log group."
  type        = map(any)
  default     = {}
}

variable "env_vars" {
  description = "Map of environment variables to set on the lambda."
  type        = map(any)
  default     = {}
}

variable "vpc_settings" {
  type        = map(any)
  description = "Configuration block for VPC settings"
  default     = null
}

variable "lambda_trigger" {
  description = "Set Permissions for LAMBDA Triggers,"
  type        = bool
  default     = false
}

variable "trigger_bucket_arn" {
  description = "Lambda Trigger S3 Bucket ARN"
  type        = string
  default     = ""
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1"
  type        = number
  default     = -1
}
