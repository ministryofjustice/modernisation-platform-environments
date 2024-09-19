variable "create_pipeline_schedule" {
  type        = bool
  default     = false
  description = "Create pipeline trigger"
}

variable "pipeline_name" {
  type        = string
  description = "Name of the pipeline trigger"
}

variable "description" {
  type        = string
  description = "Short description of the pipeline trigger"
}

variable "time_window_mode" {
  type        = string
  default     = "OFF"
  description = "(Optional) The time window mode e.g. OFF/FLEXIBLE"
}

variable "maximum_window_in_minutes" {
  type = number
  default = null
  description = "(Optional) The maximum time window in minutes"
}

variable "schedule_expression" {
  type        = string
  description = "Schedule expression for the pipeline trigger"
}

variable "schedule_expression_timezone" {
  type        = string
  description = "Schedule expression time zone for the pipeline trigger"
  default     = "Europe/London"
}

variable "state_machine_arn" {
  type        = string
  description = "The ARN of the step function"
}

variable "step_function_execution_role_arn" {
  type        = string
  description = "The ARN of the step function execution role"
}