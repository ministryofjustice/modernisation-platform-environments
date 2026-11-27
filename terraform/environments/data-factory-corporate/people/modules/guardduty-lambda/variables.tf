variable "name" {
  description = "Name of the lambda function."
  type        = string
  default     = "quarantine-lambda"
}

variable "quarantine_statuses" {
  description = "List of scan result statuses that should trigger quarantine."
  type        = list(string)
  default     = ["THREATS_FOUND", "FAILED", "ACCESS_DENIED", "UNSUPPORTED"]
}

variable "runtime" {
  description = "Runtime for the Lambda function."
  type        = string
  default     = "python3.12"
}

variable "lambda_kms_key_arn" {
  description = "KMS key ARN used to encrypt Lambda environment variables."
  type        = string
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for the Lambda function."
  type        = number
  default     = 5
}

# Lambda function handler, e.g., "lambda.lambda_handler" for a file named lambda.py with a function named lambda_handler.
variable "lambda_handler" {
  description = "Handler for the Lambda function."
  type        = string
  default     = "lambda.lambda_handler"
}

# Optional tags to apply to created resources. These are merged with the standard tags applied by the module.
variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Timeout for the Lambda function."
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Memory size for the Lambda function."
  type        = number
  default     = 256
}

variable "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule that triggers the Lambda function."
  type        = string
}

variable "quarantine_bucket_name" {
  description = "Name of the S3 bucket to move failed scan objects to."
  type        = string
}

variable "quarantine_bucket_arn" {
  description = "ARN of the S3 bucket to move failed scan objects to."
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to read objects from."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to read objects from."
  type        = string
}

variable "s3_bucket_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt objects in the landing S3 bucket."
  type        = string
}

variable "quarantine_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt objects in the quarantine S3 bucket."
  type        = string
}