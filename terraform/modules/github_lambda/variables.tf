variable "aws_account_id" {
  description = "The AWS account ID where the Lambda function will be deployed"
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the Lambda and KMS resources are deployed"
  type        = string
  default     = "eu-west-2"
}

variable "enable_outbound_federation" {
  description = "Enable outbound web identity federation"
  type        = bool
  default     = true
}

variable "github_org" {
  description = "The name of the github organization"
  type        = string
  default     = "ministryofjustice"
}

variable "github_workflows" {
  description = "The scheduled github actions workflows"
  type = map(object({
    identity = string
    inputs   = map(string)
    ref      = string
    repo     = string
    schedule = string
    timezone = string
    workflow = string
  }))
}

variable "lambda_memory_size" {
  description = "Amount of memory available to the Lambda function"
  type        = number
  default     = 256
}

variable "lambda_runtime" {
  description = "Runtime environment for the Lambda function"
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function"
  type        = number
  default     = 30
}

variable "project_name" {
  description = "The prefix to use for AWS resources created by this module"
  type        = string
  default     = "github-workflow-scheduler"
}

variable "web_identity_audience" {
  description = "The web identity audience for OCTO STS"
  type        = string
  default     = "octo-sts.dev"
}

variable "web_identity_duration_seconds" {
  description = "The duration in seconds for the web identity token"
  type        = number
  default     = 600
}

variable "web_identity_signing_algorithm" {
  description = "The signing algorithm for the web identity token"
  type        = string
  default     = "RS256"
}
