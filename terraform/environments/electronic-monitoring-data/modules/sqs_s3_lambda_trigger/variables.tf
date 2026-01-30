variable "bucket" {
  description = "aws_s3_bucket resource where notifications will originate from"
  type = object({
    id  = string
    arn = string
  })
}

variable "lambda_function_name" {
  description = "Name to use in naming SQS queue"
  type        = string
}

variable "bucket_prefix" {
  description = "The predefined local.bucket_prefix"
  type        = string
}

variable "maximum_concurrency" {
  description = "maximum concurrency to lambda"
  type        = number
  default     = 10
  nullable    = true
}

variable "max_receive_count" {
  description = "Number of receives before messages are moved to the DLQ"
  type        = number
  default     = 2
}

variable "enabled" {
  description = "whether to enable the sqs queue"
  type        = bool
  default     = true
}
