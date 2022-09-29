
variable "name" {
  description = "Name of the Bucket"
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(any)
}

variable "create_s3" {
  description = "Setup S3 Buckets"
  default     = false
}