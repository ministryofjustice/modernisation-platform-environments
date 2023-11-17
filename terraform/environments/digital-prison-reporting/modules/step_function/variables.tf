variable "region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account" {
  description = "AWS Account ID."
  default     = ""
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

variable "definition" {
  description = "(Required) The definition of the step function"
}

variable "additional_policies" {
  default     = []
  description = "(Optional) The list of Policies used for this Step Function."
}