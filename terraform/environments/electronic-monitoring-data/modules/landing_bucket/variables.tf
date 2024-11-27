variable "core_shared_services_id" {
  description = "The core shared services id"
  type        = string
}

variable "cross_account_access_role" {
  description = "An object containing the cross account number and role name."
  type = object({
    account_number = string
    role_name      = string
  })
  default = null
}

variable "data_feed" {
  description = "The data feed the bucket relates to"
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

variable "order_type" {
  description = "The name of the order type data"
  type        = string
}

variable "production_dev" {
  description = "The environment the lambda is being deployed to"
  type        = string
}

variable "received_files_bucket_id" {
  description = "The id of the bucket data will be moved to"
  type        = string
}
