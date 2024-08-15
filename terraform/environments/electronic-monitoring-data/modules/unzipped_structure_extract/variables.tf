variable "dataset_name" {
  type    = string
  nullable = false
}

variable "iam_role" {
  type = object({
    name = string
    arn  = string
    id   = string
  })
  nullable = false
}

variable "memory_size" {
    type = number
    nullable = false
    default = 240
}
variable "timeout" {
    type = number
    nullable = false
    default = 60
}
variable "function_tag" {
    type = string
    nullable = false
    default = "v0.0.0-884806f"
}

variable "env_account_id" {
  description = "The account number of the aws account"
  type        = number
}

variable "core_shared_services_id" {
  description = "The account number of the core shared services account"
  type        = number
  default     = null
  nullable    = true
}

variable "production_dev" {
  description = "The environment the lambda is being deployed to"
  type        = string
  nullable    = true
  default     = null
}

variable "json_bucket_name" {
  description = "The bucket to pull json structure from"
  type = string
  nullable = false
}

variable "athena_bucket_name" {
  description = "Bucket to dump query output into"
  type = string
  nullable = false
}