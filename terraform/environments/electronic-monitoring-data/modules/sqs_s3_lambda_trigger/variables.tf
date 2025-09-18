# var.bucket.id}-${var.s3_prefix}-${var.lambda_name

variable "bucket" {
    description = "aws_s3_bucket resource where notifications will originate from"
    type        = object({
        id  = string
        arn = string
    })
}

variable "s3_prefix" {
  description = "Prefix to filter S3 events on"
  type        = string
  nullable    = true
  default     = null
}

variable "s3_suffixes" {
  description = "Suffixes to filter S3 events on"
  type        = list(string)
  nullable    = true
  default     = null
}

variable "lambda_function_name" {
  description = "Name to use in naming SQS queue"
  type        = string
}

variable "bucket_prefix" {
  description = "The predefined local.bucket_prefix"
  type        = string
}
