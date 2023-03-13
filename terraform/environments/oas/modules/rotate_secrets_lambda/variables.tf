variable "region" {
  type        = string
  description = "Region for the module resources"
}

variable "lambda_timeout" {
  type        = string
  description = "Timeout for the rotate secret lambda function"
}

variable "lambda_runtime" {
  type        = string
  description = "Runtime for the rotate secret lambda function"
}

variable "database_name" {
  type        = string
  description = "TBC"
}

variable "database_user" {
  type        = string
  description = "TBC"
}

variable "lambda_runtime" {
  type        = string
  description = "Runtime for the rotate secret lambda function"
}

variable "log_group_retention_days" {
  type        = string
  description = "CloudWatch Log Group for Lambda function retention in days"
}
