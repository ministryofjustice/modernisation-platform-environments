variable "account_number" {
  description = "account number"
  type        = string
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "User defined extra tags to be added to all resources created in the module"
  default     = {}
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "lambda_s3_bucket" {
  description = "The S3 bucket for lambdas"
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "lambda_role" {
  description = "The role for the lambda"
  type = object({
    name                 = string
    trust_policy_path    = string
    iam_policy_path      = string
    policy_template_vars = optional(map(string), {})
  })
}

variable "lambda" {
  description = "The lambda function"
  type = object({
    function_zip_file     = string
    function_name         = string
    handler               = string
    iam_role_name         = string
    environment_variables = optional(map(string), {})
    lambda_memory_size    = optional(number, 128)
    lambda_timeout        = optional(number, 10)
    log_group = optional(object({
      name = string
    }), null)
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }), null)
  })
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID for the CloudWatch log group"
  type        = string
  default     = ""
}

variable "enable_eventbridge_invoke_permission" {
  description = "Enable eventbridge invoke permission"
  type        = bool
  default     = false
}
