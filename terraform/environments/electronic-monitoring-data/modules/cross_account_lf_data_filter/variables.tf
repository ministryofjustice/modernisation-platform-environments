variable "destination_account_id" {
  description = "The account ID of the destination account"
  type        = string
}

variable "destination_account_role_arn" {
  description = "The ARN of the role in the destination account"
  type        = string
}

variable "database_name" {
  description = "The name of the database"
  type        = string
}

variable "table_name" {
  description = "The name of the table"
  type        = string
}

variable "table_filter" {
  description = "SQL filter"
  type        = string
}

variable "data_bucket_lf_arn" {
  description = "The ARN of the data bucket in the destination account"
  type        = string
}
