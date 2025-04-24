variable "create_eventbridge_schedule" {
  type        = bool
  default     = false
  description = "Create eventbridge trigger"
}

variable "enable_eventbridge_schedule" {
  type        = bool
  default     = false
  description = "Enable/Disable eventbridge trigger"
}

variable "eventbridge_trigger_name" {
  type        = string
  description = "Name of the eventbridge trigger"
}

variable "description" {
  type        = string
  description = "Short description of the eventbridge trigger"
}

variable "time_window_mode" {
  type        = string
  default     = "OFF"
  description = "(Optional) The time window mode e.g. OFF/FLEXIBLE"
}

variable "maximum_window_in_minutes" {
  type        = number
  default     = null
  description = "(Optional) The maximum time window in minutes"
}

variable "schedule_expression" {
  type        = string
  description = "Schedule expression for the eventbridge trigger"
}

variable "schedule_expression_timezone" {
  type        = string
  description = "Schedule expression time zone for the eventbridge trigger"
  default     = "Europe/London"
}

variable "arn" {
  type        = string
  description = "The ARN of the eventbridge target"
}

variable "role_arn" {
  type        = string
  description = "The role ARN of the eventbridge target"
}

variable "input" {
  type        = string
  description = "The input string of eventbridge target"
}
