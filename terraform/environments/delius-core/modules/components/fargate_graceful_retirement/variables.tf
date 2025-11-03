variable "restart_time" {
  description = "The time at which to restart the ECS task"
  type        = string
  default     = "22:00"
}

variable "restart_day_of_the_week" {
  description = "The day of the week to restart the ECS task"
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

variable "environment" {
  description = "Environment name (dev, stage, preprod, prod etc)"
  type        = string
}

variable "extra_environment_vars" {
  description = "Optional env specific envs that needs to be injected."
  type        = map(string)
  default     = {}
}
