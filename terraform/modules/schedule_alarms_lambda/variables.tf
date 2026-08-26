variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "start_time" {
  description = "Start time for disabling alarms (HH:MM)"
  type        = string
  default     = "22:45"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.start_time))
    error_message = "Start time must be in the format HH:MM (24-hour clock)."
  }
}

variable "end_time" {
  description = "End time for enabling alarms (HH:MM)"
  type        = string
  default     = "06:15"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.end_time))
    error_message = "End time must be in the format HH:MM (24-hour clock)."
  }
}

variable "disable_weekend" {
  description = "Whether to disable alarms for the entire weekend"
  type        = bool
  default     = true
}

variable "lambda_log_level" {
  description = "Log level for the Lambda function"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.lambda_log_level)
    error_message = "Log level must be one of DEBUG, INFO, WARNING, or ERROR"
  }
}

variable "alarm_list" {
  description = "List of specific alarms to manage (empty list means all alarms)"
  type        = list(string)
  default     = []
}

variable "alarm_patterns" {
  description = "List of alarm name patterns to match (e.g., ['alarm-name-*', '*-other-alarm'])"
  type        = list(string)
  default     = []
}
