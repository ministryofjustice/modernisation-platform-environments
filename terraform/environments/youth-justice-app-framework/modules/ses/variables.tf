variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
  default     = {}
}

variable "ses_domain_identities" {
  type        = list(string)
  description = "SES domain identities to verify"
}

variable "key_id" {
  type        = string
  description = "The KMS key ID to use for the secret"
}
