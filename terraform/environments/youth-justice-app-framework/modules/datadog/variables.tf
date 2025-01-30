
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "datadog_integration_external_id" {
  description = "The external ID for the Datadog integration"
  type        = string
}