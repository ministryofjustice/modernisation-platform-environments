variable "environment" {
  description = "Deployment environment name"
  type        = string

  validation {
    condition     = contains(["production", "preproduction", "test", "development"], var.environment)
    error_message = "environment must be one of: production, preproduction, test, development."
  }
}

variable "airflow_project" {
  description = "Airflow project prefix used in the MWAA service account name"
  type        = string
}

variable "airflow_workflow" {
  description = "Airflow workflow used in the MWAA service account name"
  type        = string
}

variable "role_name_suffix" {
  description = "Suffix used when constructing the IAM role name"
  type        = string
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
}

variable "oidc_arn" {
  description = "ARN of the OIDC identity provider"
  type        = string
}

variable "oidc_cluster_identifier" {
  description = "OIDC cluster identifier used in condition keys"
  type        = string
}

variable "iam_policy_documents" {
  description = "List of IAM policy JSON documents to create and attach to the role"
  type        = list(string)
  default     = []
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600
}