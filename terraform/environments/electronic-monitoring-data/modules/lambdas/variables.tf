variable "filename" {
  description = "The path to the function's deployment package within the local filesystem."
  type        = string
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
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs to attach to your Lambda Function."
  type        = list(string)
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the package file specified in the filename."
  type        = string
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
  default     = "python3.11"
}

variable "security_group_ids" {
  description = "List of security group IDs associated with the Lambda function."
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function."
  type        = list(string)
}

variable "environment_variables" {
  description = "A map that defines environment variables for the Lambda function."
  type        = map(string)
}

variable "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for the Lambda function."
  type        = number
  default     = 10
}
