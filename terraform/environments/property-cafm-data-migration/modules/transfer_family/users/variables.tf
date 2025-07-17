variable "server_id" {
  description = "ID of the AWS Transfer Family server"
  type        = string
}

variable "user_name" {
  description = "Name of the SFTP user"
  type        = string
}

variable "s3_bucket" {
  description = "Name of the S3 bucket to mount"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to allow for encryption"
  type        = string
}