variable "aws_account_id" {
  description = "The AWS account ID where the Lambda function will be deployed"
  type        = string
}

variable "aws_accounts_parameter_name" {
  description = "The name of the AWS SSM parameter that contains the Security Hub source account IDs"
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
  description = "The Octo STS identity configured in the target repository with issues: write permission"
  type        = string
  default     = "platops_securityhub_github_issue_identifier"
}

variable "github_repo" {
  description = "The name of the GitHub repository where Security Hub finding issues are created"
  type        = string
}

variable "valid_severity_labels" {
  description = "Accepted Security Hub severity labels used to validate the selected finding severities"
  type        = list(string)
  default     = ["INFORMATIONAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"]

  validation {
    condition = length(var.valid_severity_labels) > 0 && alltrue([
      for label in var.valid_severity_labels : contains(
        ["INFORMATIONAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"],
        label
      )
    ])
    error_message = "valid_severity_labels must contain one or more valid Security Hub severity labels."
  }
}

variable "resource_keys_to_exclude" {
  description = "Top-level resource keys excluded from GitHub issue summaries"
  type        = list(string)
  default     = ["Tags", "Details"]

  validation {
    condition = alltrue([
      for key in var.resource_keys_to_exclude : try(length(trimspace(key)) > 0, false)
    ])
    error_message = "resource_keys_to_exclude must contain only non-empty resource keys."
  }
}

variable "finding_severity_labels" {
  description = "Security Hub finding severity labels that trigger GitHub issues"
  type        = list(string)
  default     = ["CRITICAL"]

  validation {
    condition = length(var.finding_severity_labels) > 0 && alltrue([
      for label in var.finding_severity_labels : contains(
        var.valid_severity_labels,
        label
      )
    ])
    error_message = "finding_severity_labels must contain one or more valid Security Hub severity labels."
  }
}

variable "finding_grace_period" {
  description = "Maximum minutes between a finding's CreatedAt and UpdatedAt for issue creation; this is a best-effort filter, not deduplication"
  type        = number
  default     = 10

  validation {
    condition     = try(var.finding_grace_period >= 0 && floor(var.finding_grace_period) == var.finding_grace_period, false)
    error_message = "finding_grace_period must be a non-negative whole number of minutes."
  }
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
  default     = "securityhub-finding-issue-generator"
}

variable "securityhub_ignore_findings_parameter_name" {
  description = "The name of the AWS SSM parameter that contains ignored Security Hub finding descriptions"
  type        = string
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
