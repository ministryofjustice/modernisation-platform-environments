variable "data_feed" {
  description = "The data feed the bucket relates to"
  type        = string
}

variable "local_bucket_prefix" {
  description = "The predefined local.bucket_prefix"
}

variable "local_tags" {
  description = "The predefined local.tags"
  type        = map(string)
}

variable "logging_bucket" {
  description = "Bucket to use for logging"
  type        = string
}

variable "order_type" {
  description = "An integer relating to the order type"
  type        = string
}

variable "supplier_bucket" {
  description = "The name of the bucket containing data to be sent"
  type        = string
}
