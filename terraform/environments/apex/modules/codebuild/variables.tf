variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}