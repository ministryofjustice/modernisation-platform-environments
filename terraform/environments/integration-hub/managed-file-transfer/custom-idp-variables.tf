variable "enable_custom_idp" {
  type        = bool
  default     = false
  description = "Create future custom identity provider foundations without changing the live Transfer server."
}

variable "custom_idp_attach_vpc" {
  type        = bool
  default     = true
  description = "Attach the future custom identity provider Lambda to the isolated VPC."
}

variable "custom_idp_existing_users_table_name" {
  type        = string
  default     = ""
  description = "Optional existing DynamoDB users table name for the custom identity provider."
}

variable "custom_idp_existing_identity_providers_table_name" {
  type        = string
  default     = ""
  description = "Optional existing DynamoDB identity providers table name for the custom identity provider."
}

variable "custom_idp_username_delimiter" {
  type        = string
  default     = "@@"
  description = "Delimiter used to distinguish username and identity provider in the future custom identity provider flow."

  validation {
    condition     = contains(["@", "@@"], var.custom_idp_username_delimiter)
    error_message = "custom_idp_username_delimiter must be either @ or @@."
  }
}

variable "custom_idp_log_level" {
  type        = string
  default     = "INFO"
  description = "Log verbosity for the future custom identity provider Lambda."

  validation {
    condition     = contains(["INFO", "DEBUG"], upper(var.custom_idp_log_level))
    error_message = "custom_idp_log_level must be INFO or DEBUG."
  }
}

variable "custom_idp_enable_tracing" {
  type        = bool
  default     = false
  description = "Enable X-Ray tracing for the future custom identity provider Lambda."
}

variable "custom_idp_allow_secrets_manager" {
  type        = bool
  default     = false
  description = "Grant the future custom identity provider Lambda permission to read Secrets Manager secrets."
}