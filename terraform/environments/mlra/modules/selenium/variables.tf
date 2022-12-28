variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "environment" {
  type        = string
  description = "Environment of the application"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "s3_lifecycle_expiration_days" {
  type        = string
  description = "S3 Bucket lifecycle configuration expiration days"
}

variable "s3_lifecycle_noncurr_version_expiration_days" {
  type        = string
  description = "S3 Bucekt lifecycle configuration noncurrent version expiration days"
}

variable "application_test_url" {
  type        = string
  description = "Endpoint to test the application with Selenium upon"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}
