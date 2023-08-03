variable "region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account" {
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
  default     = 14
}

variable "memory_size" {
  description = "Amount of memory to allocate to the lambda function."
  type        = number
  default     = 2048
}

variable "namespace" {
  description = "Namespacing for multiple environments in a single stage"
  default     = ""
}

variable "publish" {
  description = "Enable versioning for this lambda"
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
  default     = false  
}

variable "trigger_bucket_arn" {
  description = "Lambda Trigger S3 Bucket ARN"
  type        = string
  default     = ""
}

<<<<<<< HEAD
=======
# Lambda Layers
variable "layer_name" {
  description = "Name of Lambda Layer to create"
  type        = string
  default     = ""
}

variable "local_file" {
  description = "The path to the local Layer binary File."
  default     = null
  type        = string
}

variable "layer_skip_destroy" {
  description = "Whether to retain the old version of a previously deployed Lambda Layer."
  type        = bool
  default     = false
}

variable "license_info" {
  description = "License info for your Lambda Layer. Eg, MIT or full url of a license."
  type        = string
  default     = ""
}

variable "compatible_runtimes" {
  description = "A list of Runtimes this layer is compatible with. Up to 5 runtimes can be specified."
  type        = list(string)
  default     = []
}

variable "compatible_architectures" {
  description = "A list of Architectures Lambda layer is compatible with. Currently x86_64 and arm64 can be specified."
  type        = list(string)
  default     = null
}

variable "s3_existing_package" {
  description = "The S3 bucket object with keys bucket, key, version pointing to an existing zip-file to use"
  type        = map(string)
  default     = null
}

>>>>>>> 24a8a50fd (Terraform Transfer Component)
variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = null
<<<<<<< HEAD
}

=======
}
>>>>>>> 24a8a50fd (Terraform Transfer Component)
