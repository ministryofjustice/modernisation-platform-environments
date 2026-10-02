variable "role_name" {
  description = "Name of the IAM role."
  type        = string
}

variable "trusted_account_id" {
  description = "AWS account ID allowed to assume the role."
  type        = string

  #validation {
  #  condition     = can(regex("^\\d{12}$", var.trusted_account_id))
  #  error_message = "trusted_account_id must be a 12-digit AWS account ID."
  #}
}

variable "max_session_duration" {
  description = "Maximum session duration for the IAM role, in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 600 && var.max_session_duration <= 14400
    error_message = "max_session_duration must be between 600 and 14400 seconds."
  }
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "s3_prefix" {
  description = "S3 key prefix allocated to the external client."
  type        = string
  default     = ""
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket containing the allocated prefix."
  type        = string
}

variable "s3_object_actions" {
  description = "S3 object actions allowed within the allocated prefix."
  type        = list(string)

  default = []
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt objects in the S3 bucket."
  type        = string
  #validation {
  #  condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:\\d{12}:key/[a-f0-9-]+$", var.kms_key_arn))
  #  error_message = "kms_key_arn must be a valid KMS key ARN."
  #}
}

variable "kms_actions" {
  description = "KMS cryptographic actions allowed through Amazon S3."
  type        = list(string)

  default = []
}

variable "glue_database_arn" {
  description = "ARN of the Glue database allocated to the external client."
  type        = string
}

variable "glue_catalog_arn" {
  description = "ARN of the Glue catalog."
  type        = string
}

variable "glue_table_name" {
  description = "Glue table name, either for a specific table or all tables in the database."
  type        = string
}

variable "glue_actions" {
  description = "Glue table actions allowed within the allocated database."
  type        = list(string)

  default = []
}