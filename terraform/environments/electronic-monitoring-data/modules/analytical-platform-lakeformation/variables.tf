variable "destination_account_id" {
  description = "The account ID of the destination account"
  type        = string
}

variable "data_locations" {
  description = "A list of data locations to share"
  type = list(object({
    data_location = string
  }))
}

variable "databases_to_share" {
  description = "A list of databases to share"
  type = list(object({
    source_database  = string
    source_table     = string
    row_filter       = string
    permissions      = list(string)
    excluded_columns = list(string)
  }))
}
