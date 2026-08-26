variable "region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
  type        = string
}

variable "account" {
  description = "AWS Account ID."
  default     = ""
  type        = string
}

variable "enable_gateway" {
  type        = bool
  default     = false
  description = "(Optional) Create Lambda, If Set to Yes"
}

variable "name" {
  description = "(Required) Name of the service"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the log group."
  type        = map(any)
  default     = {}
}

variable "lambda_arn" {
  description = "(Required) ARN of the Lambda"
  type        = string
}

variable "lambda_name" {
  description = "(Required) Name of the Lambda Service"
  type        = string
}

variable "subnet_ids" {
  description = "An List of VPC subnet IDs to use in the subnet group"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "An List of VPC SGroups"
  type        = list(string)
  default     = []
}

variable "endpoint_ids" {
  description = "An List of VPC Endpoint IDS"
  type        = list(string)
  default     = []
}