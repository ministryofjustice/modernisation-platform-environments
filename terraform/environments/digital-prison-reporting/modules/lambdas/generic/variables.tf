# tflint-ignore-file: terraform_required_version, terraform_required_providers

variable "region" {
  type        = string
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account" {
  type        = string
  description = "AWS Account ID."
  default     = ""
}

variable "enable_lambda" {
  type        = bool
  default     = false
  description = "(Optional) Create Lambda, If Set to Yes"
}

variable "s3_bucket" {
  description = <<EOF
  The S3 bucket location containing the function's deployment package. Conflicts with filename and image_uri. 
  This bucket must reside in the same AWS region where you are creating the Lambda function.
  EOF
  default     = null
  type        = string
}

variable "s3_key" {
  description = "The S3 key of an object containing the function's deployment package. Conflicts with filename and image_uri."
  default     = null
  type        = string
}

variable "filename" {
  description = "The path to the function's deployment package within the local filesystem. If defined, The s3_-prefixed options and image_uri cannot be used."
  default     = null
  type        = string
}

variable "handler" {
  description = "(Required) Path to the code entrypoint."
  type        = string
}

variable "log_retention_in_days" {
  description = "Log retention in number of days."
  type        = number
  default     = 7
}

variable "memory_size" {
  description = "Amount of memory to allocate to the lambda function."
  type        = number
  default     = 2048
}

variable "namespace" {
  type        = string
  description = "Namespacing for multiple environments in a single stage"
  default     = ""
}

variable "publish" {
  description = "Enable versioning for this lambda"
  type        = bool
  default     = false
}

variable "name" {
  description = "(Required) Name of the service"
  type        = string
}

variable "tracing" {
  description = "Enable Tracing on Lambda"
  type        = string
}

variable "policies" {
  description = "Additional IAM policies to attach to the lambda's IAM role."
  type        = list(any)
  default     = []
}

variable "runtime" {
  description = "Runtime the lambda function should use."
  type        = string
  default     = "nodejs14.x"
}

variable "tags" {
  description = "Additional tags to apply to the log group."
  type        = map(any)
  default     = {}
}

variable "timeout" {
  description = "Value for the max number of seconds the lambda function will run."
  type        = number
  default     = 20
}

variable "env_vars" {
  description = "Map of environment variables to set on the lambda."
  type        = map(any)
  default     = {}
}

variable "vpc_settings" {
  type        = map(any)
  description = "Configuration block for VPC settings"
  default     = null
}

variable "lambda_trigger" {
  description = "Set Permissions for LAMBDA Triggers,"
  type        = bool
  default     = false
}

variable "trigger_bucket_arn" {
  description = "Lambda Trigger S3 Bucket ARN"
  type        = string
  default     = ""
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = null
}

variable "secret_arns" {
  description = "ARNs of the secrets this Lambda will require Get access to"
  type        = list(string)
  default     = []
}
