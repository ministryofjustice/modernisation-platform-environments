variable "data_feed" {
  description = "The data feed the bucket relates to"
}

variable "local_bucket_prefix" {
  description = "The predefined local.bucket_prefix"
}

variable "local_tags" {
  description = "The predefined local.tags"
}

variable "logging_bucket" {
    description = "Bucket to use for logging"
}

variable "order_type" {
  description = "An integer relating to the order type"
}

variable "supplier_account_id" {
  description = "The AWS account number for supplier"
}
