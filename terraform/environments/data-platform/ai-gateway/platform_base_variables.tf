variable "networking" {
  type = list(any)
}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "guardrail_diagnostics_key_version" {
  type        = number
  default     = 1
  description = "Version nonce incremented whenever the write-only guardrail diagnostics key is rotated"

  validation {
    condition     = var.guardrail_diagnostics_key_version > 0 && floor(var.guardrail_diagnostics_key_version) == var.guardrail_diagnostics_key_version
    error_message = "guardrail_diagnostics_key_version must be a positive integer."
  }
}

variable "guardrail_diagnostics_retention_days" {
  type        = number
  default     = 7
  description = "Number of days diagnostic prompt captures are retained"

  validation {
    condition     = var.guardrail_diagnostics_retention_days >= 1 && var.guardrail_diagnostics_retention_days <= 30
    error_message = "guardrail_diagnostics_retention_days must be between 1 and 30 days."
  }
}
