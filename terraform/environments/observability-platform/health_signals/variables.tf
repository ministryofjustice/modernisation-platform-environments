variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources"
}

variable "region" {
  type        = string
  default     = "eu-west-2"
}

variable "schedule_expression" {
  type        = string
  default     = "rate(5 minutes)"
}

variable "health_namespace" {
  type        = string
  default     = "Custom/Health"
}

variable "tenant_role_name" {
  type        = string
  default     = "observability-platform-health-signal-reader"
}

variable "tenants" {
  type = list(object({
    account_id   = string
    tenant       = string
    environment  = string
  }))
  default = []
}

variable "warn_threshold" {
  type    = number
  default = 0.90
}

variable "crit_threshold" {
  type    = number
  default = 0.95
}
