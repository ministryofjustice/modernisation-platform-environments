variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment for the log-groups"
  type        = string
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the AWS KMS key to be used to encrypt secret values."
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use for encryption"
  type        = string
  default     = null
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "ds_log_group_name" {
  description = "Directory service log group"
  type        = string
}