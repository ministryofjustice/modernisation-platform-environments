variable "database_name" {
  type        = string
  description = "The name of the Glue catalog database to create."

  validation {
    condition     = length(var.database_name) < 50
    error_message = "The database name must be less than 50 characters."
  }
}

variable "storage" {
  description = "Database default S3 location; Lake Formation registration is managed separately."
  type = object({
    bucket_name = string
    prefix      = string
  })

  validation {
    condition     = length(trim(var.storage.prefix, "/")) > 0 && !startswith(var.storage.prefix, "/")
    error_message = "storage.prefix must be a non-empty S3 key prefix and must not start with '/'."
  }
}

variable "tags" {
  type        = map(string)
  description = "AWS resource tags to apply to the database."
  default     = {}
}

variable "lf_tags" {
  type        = map(string)
  description = "Existing Lake Formation tag keys and values to associate with the database."
  default     = {}
}