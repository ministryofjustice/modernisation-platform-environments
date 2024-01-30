variable "name" {
  type = string
}

variable "identity_centre_team" {
  type = string
}

variable "aws_accounts" {
  type = map(object({
    cloudwatch_enabled = optional(bool)
    xray_enabled       = optional(bool)
  }))
}
