variable "enable_lambda_trigger" {
  description = "enable lambda trigger"
  type        = bool
}

variable "event_name" {
  description = "Name of the cloudwatch lambda trigger event"
  type        = string
}

variable "trigger_schedule_expression" {
  description = "(Optional) The trigger schedule expression e.g. cron(0 20 * * ? *) or rate(5 minutes)"
  type        = string
  default     = null
}

variable "trigger_event_pattern" {
  description = "(Optional) The trigger event pattern"
  type        = string
  default     = null
}

variable "trigger_input_event" {
  description = "(Optional) JSON event which will be sent to the lambda"
  type        = string
  default     = null
}

variable "lambda_function_name" {
  description = "The lambda name"
  type        = string
}

variable "lambda_function_arn" {
  description = "The lambda arn"
  type        = string
}

variable "event_bus_name" {
  description = "Name of the event bus"
  type        = string
  default     = "default"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}