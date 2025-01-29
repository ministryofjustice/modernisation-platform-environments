variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "filter_tags" {
  description = "A map of tags to add to all resources"
  type        = list(string)
}
