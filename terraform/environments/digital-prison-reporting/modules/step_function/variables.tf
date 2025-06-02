variable "region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
  type        = string
}

variable "account" {
  description = "AWS Account ID."
  default     = ""
  type        = string
}

variable "enable_step_function" {
  type        = bool
  default     = false
  description = "(Optional) Create Step Function, If Set to Yes"
}

variable "step_function_name" {
  description = "(Required) The name of the step function."
  type        = string
}

variable "step_function_log_retention_in_days" {
  description = "(Optional) The log retention in days for the step-function."
  default     = 7
  type        = string
}

variable "dms_task_time_out" {
  description = "(Optional) The duration after which the DMS load step is deemed to have failed."
  default     = 86400 # 24 hours
  type        = number
}

variable "definition" {
  description = "(Required) The definition of the step function"
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "step_function_execution_role_arn" {
  type        = string
  description = "The ARN of the step function execution role"
}