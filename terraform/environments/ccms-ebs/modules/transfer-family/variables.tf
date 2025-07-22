variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "app_name" {
  type        = string
  description = "Application Name"
}

variable "aws_identity_centre_store_arn" {
  type        = string
  description = "ARN for AWS Identity Centre Store"
}

variable "aws_identity_centre_sso_group_id" {
  type        = string
  description = "Group ID that should be used to grant SSO access to Web App. Federated from a corresponding group in Entra/Github"
  default     = "c64272c4-30a1-7039-8ffd-af791143da2e" #--azure-aws-sso-laa-ccms-ebs-s3-cashoffice
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name to serve to Transfer Family Web App"
}
