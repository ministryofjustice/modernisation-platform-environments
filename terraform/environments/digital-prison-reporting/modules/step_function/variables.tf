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

variable "dms_task_time_out" {
  description = "(Optional) The duration after which the DMS load step is deemed to have failed."
  default     = 18000 # 5 hours
  type        = number
}

variable "definition" {
  description = "(Required) The definition of the step function"
}

variable "additional_policies" {
  description = "(Optional) The list of Policies used for this Step Function."
  type        = list(any)
  default     = []
}