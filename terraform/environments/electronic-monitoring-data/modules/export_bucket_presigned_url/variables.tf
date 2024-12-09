variable "allowed_ips" {
  description = "IP addresses that are allowed to get objects from bucket"
  type        = list(string)
  default     = null
}

variable "export_destination" {
  description = "An identifying name for where data in bucket will be sent"
  type        = string
}

variable "local_bucket_prefix" {
  description = "The predefined local.bucket_prefix"
  type        = string
}

variable "local_tags" {
  description = "The predefined local.tags"
  type        = map(string)
}

variable "logging_bucket" {
  description = "Bucket to use for logging"
  type = object({
    bucket = object({
      id  = string
      arn = string
    })
    bucket_policy = object({
      policy = string
    })
  })
}
