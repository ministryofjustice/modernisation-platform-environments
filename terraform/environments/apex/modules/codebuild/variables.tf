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

variable "s3_lifecycle_expiration_days" {
  type        = string
  description = "S3 Bucket lifecycle configuration expiration days"
}

variable "s3_lifecycle_noncurr_version_expiration_days" {
  type        = string
  description = "S3 Bucket lifecycle configuration noncurrent version expiration days"
}

variable "core_shared_services_production_account_id" {
  type        = string
  description = "AWS Account ID of Core Shared Services Production where the shared ECR resides"
}

variable "local_ecr_url" {
  type        = string
  description = "URL for the local ECR repo"
}

variable "application_test_url" {
  type        = string
  description = "Endpoint to test the application with Selenium upon"
}