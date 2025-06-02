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
  type = map(object({
    identity       = string
    create_records = bool
  }))
  description = "SES domain identities to create DNS records for"
}

variable "key_id" {
  type        = string
  description = "The KMS key ID to use for the secret"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnets to allow SES SMTP user to send emails"
}