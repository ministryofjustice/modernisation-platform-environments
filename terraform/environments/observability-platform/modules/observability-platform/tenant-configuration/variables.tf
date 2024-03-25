variable "environment_management" {
  type = any
}

variable "name" {
  type = string
}

variable "identity_centre_team" {
  type = string
}

variable "alerting" {
  type = map(object({
    pagerduty = optional(list(string))
    slack     = optional(list(string))
  }))
}

variable "aws_accounts" {
  type = map(object({
    cloudwatch_enabled           = optional(bool)
    cloudwatch_custom_namespaces = optional(string)
    prometheus_push_enabled      = optional(bool)
    xray_enabled                 = optional(bool)
  }))
}
