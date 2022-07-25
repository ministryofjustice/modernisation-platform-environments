variable "key" {
  type    = string
  default = "backup"
}
variable "value" {
  type    = bool
  default = true
}
variable "rules" {}
variable "application_name" {
  type        = string
  description = "The name of the application.  This will be name of the environment in Modernisation Platform"
  default     = "nomis"
  nullable    = false
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-.]{1,61}[A-Za-z0-9]$", var.application_name))
    error_message = "Invalid name for application supplied in variable app_name."
  }
}
variable "business_unit" {
  type        = string
  description = "This corresponds to the VPC in which the application resides"
  default     = "hmpps"
  nullable    = false
}

variable "environment" {
  type        = string
  description = "Application environment - i.e. the terraform workspace"
}
variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}