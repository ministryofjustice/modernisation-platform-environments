variable "s3_source" {
  type        = string
  description = ""
}

variable "s3_bucket_landing" {
  type        = string
  description = "AWS S3 call centre landing bucket name"
}

variable "s3_bucket_logs" {
  type        = string
  description = "AWS S3 call centre logs bucket name"
}

# variable "acl" {
#   type        = string
#   description = ""
# }

variable "versioning_enabled" {
  type        = bool
  description = ""
}

# variable "logging_enabled" {
#   type        = bool
#   description = ""
# }

variable "force_destroy" {
  type        = bool
  description = ""
}
