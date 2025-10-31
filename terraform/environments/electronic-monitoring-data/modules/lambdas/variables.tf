variable "is_image" {
  description = "Whether the object is an image or not"
  type        = bool
  default     = false
}

variable "filename" {
  description = "The path to the function's deployment package within the local filesystem."
  type        = string
  nullable    = true
  default     = null
}

variable "image_name" {
  description = "The name of the image function."
  type        = string
  nullable    = true
  default     = null
}

variable "function_name" {
  description = "A unique name for your Lambda Function."
  type        = string
}

variable "role_arn" {
  description = "The Amazon Resource Name (ARN) of the function's execution role."
  type        = string
}

variable "role_name" {
  description = "The name of the IAM role to attach policies."
  type        = string
}

variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
  nullable    = true
  default     = null
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs to attach to your Lambda Function."
  type        = list(string)
  nullable    = true
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the package file specified in the filename."
  type        = string
  nullable    = true
  default     = null
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = 900
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime."
  type        = number
  default     = 1024
}

variable "runtime" {
  description = "The identifier of the function's runtime."
  type        = string
  nullable    = true
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs associated with the Lambda function."
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function."
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "A map that defines environment variables for the Lambda function."
  type        = map(string)
  default     = null
  nullable    = true
}

variable "reserved_concurrent_executions" {
  description = "The amount m  of reserved concurrent executions for the Lambda function."
  type        = number
  default     = 10
}

variable "core_shared_services_id" {
  description = "The account number of the core shared services account"
  type        = number
  default     = null
  nullable    = true
}

variable "production_dev" {
  description = "The environment the lambda is being deployed to"
  type        = string
  nullable    = true
  default     = null
}

variable "ecr_repo_name" {
  description = "ECR repo in shared services acc"
  type        = string
  nullable    = false
  default     = "electronic-monitoring-data-lambdas"
}

variable "function_tag" {
  description = "Custom tag in ECR repo"
  type        = string
  nullable    = true
  default     = null
}

variable "ephemeral_storage_size" {
  description = "Size in MB of lambda ephemeral storage"
  type        = number
  default     = 512
}

variable "s3_bucket" {
  description = "The name of the S3 bucket where the Lambda layer code is stored"
  type        = string
  nullable    = true
  default     = null
}

