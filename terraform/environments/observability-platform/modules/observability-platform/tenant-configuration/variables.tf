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
    cloudwatch_enabled              = optional(bool)
    cloudwatch_custom_namespaces    = optional(string)
    prometheus_push_enabled         = optional(bool)
    amazon_prometheus_query_enabled = optional(bool)
    amazon_prometheus_workspace_id  = optional(string)
    xray_enabled                    = optional(bool)
    athena_enabled                  = optional(bool)
  }))
  default = {
    default = {
      cloudwatch_enabled              = true
      prometheus_push_enabled         = false
      amazon_prometheus_query_enabled = false
      amazon_prometheus_workspace_id  = ""
      xray_enabled                    = false
      athena_enabled                  = false
    }
  }
}
