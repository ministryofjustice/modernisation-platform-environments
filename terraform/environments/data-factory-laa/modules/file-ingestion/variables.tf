variable "kms_key_arn" {
  description = "KMS key for data lake encryption." 
  type        = string
  default     = null
}

variable "database_name" {
  description = "Name of the database to use for the output"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
