variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "app_name" {
  type        = string
  description = "Application Name"
}

variable "entra_group_name" {
  type        = string
  description = "Entra group name for federated IDP authentication (which group should be allowed to access Web App)"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name to serve to Transfer Family Web App"
}
