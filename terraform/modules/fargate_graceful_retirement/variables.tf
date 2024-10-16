variable "restart_time" {
  description = "The time to wait until invoking the Lambda function (in RFC3339 format, e.g., 2023-11-13T14:30:00Z)"
  type        = string
}

variable "restart_day_of_the_week" {
  description = "The day of the week to restart the ECS task (e.g., MONDAY)"
  type        = string
  default     = "WEDNESDAY"
  validation {
    condition     = can(regex("^(MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY)$", var.restart_day_of_the_week))
    error_message = "The restart_day_of_the_week must be one of MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, or SUNDAY"
  }
}

variable "debug_logging" {
  description = "Enable debug logging"
  type        = bool
  default     = false
}
