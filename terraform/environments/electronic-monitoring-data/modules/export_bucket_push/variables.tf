variable "core_shared_services_id" {
  description = "The core shared services id"
  type        = string
}

variable "destination_bucket_id" {
  description = "The id of the bucket data will be pushed to"
  type        = string
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

variable "production_dev" {
  description = "The environment the lambda is being deployed to"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs associated with the Lambda function."
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function."
  type        = list(string)
}
