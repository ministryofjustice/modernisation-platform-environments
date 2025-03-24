variable "destination_account_id" {
  description = "The account ID of the destination account"
}

variable "destination_account_role_arn" {
  description = "The ARN of the role in the destination account"
}

variable "database_name" {
  description = "The name of the database"
}

variable "table_name" {
  description = "The name of the table"
}

variable "table_filter" {
  description = " SQL filter"
}

variable "data_bucket_lf_arn" {
  description = "The ARN of the data bucket in the destination account"
}
