variable "account_number" {
  type        = string
  description = "Account number of current environment"
}

variable "application_name" {
  type        = string
  description = "name of application, e.g. nomis, oasys etc.."
}

variable "environment" {
  type        = string
  description = "Modernisation platform environment, e.g. development"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}