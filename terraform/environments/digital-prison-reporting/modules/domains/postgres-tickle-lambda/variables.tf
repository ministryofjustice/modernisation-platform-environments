# Lambda
variable "setup_postgres_tickle_lambda" {
  description = "Enable Postgres Tickle Lambda, True or False ?"
  type        = bool
  default     = false
}

variable "postgres_tickle_lambda_name" {
  description = "Name for the Lambda"
  type        = string
  default     = ""
}

variable "lambda_code_s3_bucket" {
  description = "Lambda Code Bucket"
  type        = string
  default     = ""
}

variable "lambda_code_s3_key" {
  description = "Lambda Code Bucket Key"
  type        = string
  default     = ""
}

variable "lambda_handler" {
  description = "Notification Lambda Handler"
  type        = string
  default     = "uk.gov.justice.digital.lambda.PostgresTickleLambda::handleRequest"
}

variable "lambda_runtime" {
  description = "Lambda Runtime"
  type        = string
  default     = "java11"
}

variable "lambda_policies" {
  description = "A List of IAM Policies to apply to the lambda"
  type        = list(string)
  default     = []
}

variable "lambda_tracing" {
  description = "Lambda Tracing"
  type        = string
  default     = "Active"
}

variable "lambda_log_retention_in_days" {
  description = "Lambda log retention in number of days."
  type        = number
  default     = 7
}

variable "lambda_timeout_in_seconds" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Amount of memory to allocate to the lambda function."
  type        = number
  default     = 256
}

variable "lambda_subnet_ids" {
  description = "Lambda Subnet ID's"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "Lambda Security Group ID's"
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "env_vars" {
  description = "Map of environment variables to set on the lambda"
  type        = map(any)
  default     = {}
}

variable "secret_arns" {
  description = "ARNs of the secrets this Lambda will require Get access to"
  type        = list(string)
  default     = []
}