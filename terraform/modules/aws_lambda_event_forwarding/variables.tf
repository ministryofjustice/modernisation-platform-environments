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

variable "aws_securityhub_lambda_configuration" {
  description = "Configuration for AWS Security Hub event forwarding to the AWS Security Hub Lambda"

  type = object({
    enabled                    = bool
    aws_securityhub_lambda_arn = optional(string)
    rule_name                  = optional(string)
  })

  default = {
    enabled = false
  }

  validation {
    condition = (
      !var.aws_securityhub_lambda_configuration.enabled ||
      (
        try(trimspace(var.aws_securityhub_lambda_configuration.aws_securityhub_lambda_arn), "") != "" &&
        try(trimspace(var.aws_securityhub_lambda_configuration.rule_name), "") != ""
      )
    )

    error_message = "When aws_securityhub_lambda_configuration.enabled is true, aws_securityhub_lambda_arn and rule_name must both be provided and non-empty."
  }
}

variable "finding_severity_labels" {
  description = "Security Hub finding severity labels to forward to the Lambda function"
  type        = list(string)
  default     = ["CRITICAL"]

  validation {
    condition = try(length(var.finding_severity_labels) > 0 && alltrue([
      for label in var.finding_severity_labels : contains(
        ["INFORMATIONAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"],
        label
      )
    ]), false)
    error_message = "finding_severity_labels must contain one or more valid Security Hub severity labels."
  }
}
