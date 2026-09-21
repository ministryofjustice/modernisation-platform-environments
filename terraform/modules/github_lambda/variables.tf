variable "github_org" {
  description = "The name of the github organization"
  type        = string
  default     = "ministryofjustice"
}

variable "github_workflows" {
  description = "The scheduled github actions workflows"
  type = map(object({
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
