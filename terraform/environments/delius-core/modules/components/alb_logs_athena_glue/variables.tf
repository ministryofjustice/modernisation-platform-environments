variable "env_name" {
  description = "The name of the env where file system is being created"
  type        = string
}

variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "alb_bucket_name" {
  description = "The name of the S3 bucket to store ALB logs"
  type        = string
}




variable "s3_versioning" {
  type        = bool
  description = "A boolean that determines whether s3 will have versioning"
  default     = true
}

variable "force_destroy_bucket" {
  type        = bool
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}

variable "access_logs_lifecycle_rule" {
  description = "Custom lifecycle rule to override the default one"
  type = list(object({
    id      = string
    enabled = string
    prefix  = string
    tags    = map(string)
    transition = list(object({
      days          = number
      storage_class = string
    }))
    expiration = object({
      days = number
    })
    noncurrent_version_transition = list(object({
      days          = number
      storage_class = string
    }))
    noncurrent_version_expiration = object({
      days = number
    })
  }))
  default = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]
}