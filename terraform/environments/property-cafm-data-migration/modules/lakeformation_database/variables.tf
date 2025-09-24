variable "database_name" {
  description = "The name of the lakeformation database"
  type        = string
}

variable "location_bucket" {
  description = "The location bucket name for the lakeformation database"
  type        = string
}

variable "location_prefix" {
  description = "The location prefix for the lakeformation database"
  type        = string
  default     = ""
}

variable "validate_location" {
  description = "Flag to validate the existence of the S3 location bucket"
  type        = bool
  default     = true
}

variable "hybrid_access_enabled" {
  description = "Flag to enable hybrid access mode for the lakeformation location"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "The KMS key identifier used for S3 bucket encryption. Can be a key ARN, alias (alias/my-key), or key ID"
  type        = string
  default     = null
}
