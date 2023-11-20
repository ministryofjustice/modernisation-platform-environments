variable "enable_lambda_trigger" {
  description = "enable lambda trigger"
  type        = bool
}

variable "event_name" {
  description = "Name of the cloudwatch lambda trigger event"
  type        = string
}

variable "trigger_schedule_expression" {
  description = "The trigger schedule expression e.g. cron(0 20 * * ? *) or rate(5 minutes)"
  type        = string
}

variable "trigger_input_event" {
  description = "JSON event which will be sent to the lambda"
  type        = string
}

variable "lambda_function_name" {
  description = "The lambda name"
  type        = string
}

variable "lambda_function_arn" {
  description = "The lambda arn"
  type        = string
}