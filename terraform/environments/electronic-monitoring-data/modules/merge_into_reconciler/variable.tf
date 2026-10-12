variable "function_to_iterate" {
  type = object({
    lambda_function_arn  = string
    lambda_function_name = string
  })
}

variable "planner_function_arn" {
  type    = string
  default = ""
}

variable "reconciliation_consumer" {
  type    = string
  default = ""

  validation {
    condition = contains(
      ["", "STAGED", "AC", "EMDI"],
      var.reconciliation_consumer,
    )
    error_message = "reconciliation_consumer must be STAGED, AC, EMDI or empty."
  }
}
