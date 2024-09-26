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

variable "supplier_bucket" {
  description = "The name of the supplier bucket containing data to be sent"
  type        = string
}
