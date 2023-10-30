variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "tags_common" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}