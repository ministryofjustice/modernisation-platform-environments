variable "data_feed" {
  description = "The data feed the bucket relates to"
  type        = string
}

variable "landing_bucket_arn" {
  description = "The arn of the bucket the iam user can access"
  type        = string
}

variable "local_bucket_prefix" {
  description = "The predefined local.bucket_prefix"
  type        = string
}

variable "local_tags" {
  description = "The predefined local.tags"
  type        = map(string)
}

variable "order_type" {
  description = "The name of the order type data"
  type        = string
}

variable "rotation_lambda" {
  description = "ARN of lambda to rotate keys"
  type        = object({ lambda_function_arn : string, lambda_function_name : string })
}

variable "rotation_lambda_role_name" {
  description = "Name of role lambda assumes to rotate keys"
  type        = string
}
