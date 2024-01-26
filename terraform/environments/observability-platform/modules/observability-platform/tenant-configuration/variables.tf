variable "environment_management" {
  type = any
}

variable "name" {
  type = string
}

variable "identity_centre_team" {
  type = string
}

variable "aws_accounts" {
  type = map(object({
    cloudwatch_enabled           = optional(bool)
    cloudwatch_custom_namespaces = optional(string)
    prometheus_push_enabled      = optional(bool)
    xray_enabled                 = optional(bool)
  }))
}
