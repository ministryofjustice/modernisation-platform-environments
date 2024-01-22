variable "environment_management" {
  type = any # TODO: review this
}

variable "name" {
  type = string
}

variable "identity_centre_team" {
  type = string
}

variable "aws_accounts" {
  type = map(object({
    cloudwatch_enabled           = bool
    cloudwatch_custom_namespaces = string
    prometheus_enabled           = bool
    xray_enabled                 = bool
  }))
}
