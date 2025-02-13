variable "application_data" {
  type = map(any)
}

variable "environment" {
  description = "The environment for the application"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}