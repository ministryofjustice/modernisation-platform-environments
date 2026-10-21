variable "aws_health_lambda_configuration" {
  description = "Configuration for AWS Health event forwarding to the AWS Health lambda"

  type = object({
    enabled               = bool
    aws_health_lambda_arn = optional(string)
    rule_name             = optional(string)
  })

  default = {
    enabled = false
  }

  validation {
    condition = (
      !var.aws_health_lambda_configuration.enabled ||
      (
        try(trimspace(var.aws_health_lambda_configuration.aws_health_lambda_arn), "") != "" &&
        try(trimspace(var.aws_health_lambda_configuration.rule_name), "") != ""
      )
    )

    error_message = "When aws_health_lambda_configuration.enabled is true, aws_health_lambda_arn and rule_name must both be provided and non-empty."
  }
}
