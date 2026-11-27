variable "bucket_name" {
  description = "Name of the bucket to register with Lake Formation."
  type        = string
}

variable "prefix" {
  description = "S3 prefix to register; empty registers the whole bucket. Do not overlap registered locations."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt objects at this location."
  type        = string
}

variable "role_name" {
  description = "Unique name of the IAM role Lake Formation uses for this location."
  type        = string
}

variable "tags" {
  description = "Tags applied to the location access role."
  type        = map(string)
  default     = {}
}