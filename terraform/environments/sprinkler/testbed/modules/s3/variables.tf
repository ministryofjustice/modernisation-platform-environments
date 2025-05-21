variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}
