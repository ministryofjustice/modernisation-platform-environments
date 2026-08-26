# Lambda
variable "setup_step_function_notification_lambda" {
  description = "Enable Step Function Notification Lambda, True or False ?"
  type        = bool
  default     = false
}

variable "step_function_notification_lambda" {
  description = "Name for Notification Lambda Name"
  type        = string
  default     = ""
}

variable "s3_file_transfer_lambda_code_s3_bucket" {
  description = "S3 File Transfer Lambda Code Bucket ID"
  type        = string
  default     = ""
}

variable "reporting_lambda_code_s3_key" {
  description = "S3 File Transfer Lambda Code Bucket KEY"
  type        = string
  default     = ""
}

variable "step_function_notification_lambda_handler" {
  description = "Notification Lambda Handler"
  type        = string
  default     = "uk.gov.justice.digital.lambda.StepFunctionDMSNotificationLambda::handleRequest"
}

variable "step_function_notification_lambda_runtime" {
  description = "Lambda Runtime"
  type        = string
  default     = "java11"
}

variable "step_function_notification_lambda_policies" {
  description = "An List of Notification Lambda Policies"
  type        = list(string)
  default     = []
}

variable "step_function_notification_lambda_tracing" {
  description = "Lambda Tracing"
  type        = string
  default     = "Active"
}

variable "step_function_notification_lambda_trigger" {
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