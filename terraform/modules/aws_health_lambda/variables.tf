variable "aws_account_id" {
  description = "The AWS account ID where the Lambda function will be deployed"
  type        = string
}

variable "aws_accounts_parameter_name" {
  description = "The name of the AWS SSM parameter that contains the AWS account IDs"
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the Lambda and KMS resources are deployed"
  type        = string
  default     = "eu-west-2"
}

variable "github_org" {
  description = "The name of the github organization"
  type        = string
  default     = "ministryofjustice"
}

variable "github_identity" {
  description = "The Octo STS identity configured with issues: write and organization_projects: write permissions"
  type        = string
  default     = "platops_github_issue_identifier"
}

variable "github_repo" {
  description = "The name of the GitHub repository where AWS Health issues are created"
  type        = string
}

variable "github_project_number" {
  description = "The number of the GitHub organisation project receiving AWS Health issues"
  type        = number

  validation {
    condition     = try(var.github_project_number > 0 && floor(var.github_project_number) == var.github_project_number, false)
    error_message = "github_project_number must be a positive whole number."
  }
}

variable "github_project_fields_page_size" {
  description = "Number of GitHub project fields requested per API page"
  type        = number
  default     = 30

  validation {
    condition     = try(var.github_project_fields_page_size >= 1 && var.github_project_fields_page_size <= 100 && floor(var.github_project_fields_page_size) == var.github_project_fields_page_size, false)
    error_message = "github_project_fields_page_size must be a whole number between 1 and 100."
  }
}

variable "github_issue_source" {
  description = "The case-sensitive suffix of the Source single-select option to set on the GitHub project item"
  type        = string
  default     = "Support"

  validation {
    condition     = try(length(trimspace(var.github_issue_source)) > 0, false)
    error_message = "github_issue_source must be non-empty."
  }
}

variable "ignore_findings_parameter_name" {
  description = "The name of the AWS SSM parameter that contains the ignore findings value"
  type        = string
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
  default     = "github-project-issue-generator"
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
