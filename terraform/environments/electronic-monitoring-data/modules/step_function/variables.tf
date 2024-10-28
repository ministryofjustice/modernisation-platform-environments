variable "name" {
  type     = string
  nullable = false
}

variable "iam_policies" {
  type = map(object({
    arn = string
  }))
  nullable = false
}

variable "variable_dictionary" {
  type     = map(any)
  nullable = false
}

variable "state_machine_type" {
  description = "The type of the state machine, must be STANDARD type or EXPRESS type"
  type        = string
  default     = "STANDARD"
  nullable    = false
}