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
  description = "An List of Notification Lambda Policies"
  type        = list(string)
  default     = []
}

variable "lambda_tracing" {
  description = "Lambda Tracing"
  type        = string
  default     = "Active"
}

variable "lambda_trigger" {
  description = "Name for Notification Lambda Trigger Name"
  type        = string
  default     = ""
}

variable "lambda_log_retention_in_days" {
  description = "Lambda log retention in number of days."
  type        = number
  default     = 7
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

variable "heartbeat_endpoint_secret_id" {
  description = "The secret ID of the secret containing the heartbeat endpoint details"
  type        = string
  default     = ""
}

variable "additional_env_vars" {
  description = "Map of additional environment variables to set on the lambda"
  type        = map(any)
  default     = {}
}