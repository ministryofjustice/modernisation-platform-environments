variable "docs_versions" {
  type = map(any)
}

variable "authorizer_versions" {
  type = map(any)
}

variable "get_glue_metadata_versions" {
  type = map(any)
}

variable "presigned_url_versions" {
  type = map(any)
}

variable "athena_load_versions" {
  type = map(any)
}

variable "create_metadata_versions" {
  type = map(any)
}

variable "resync_unprocessed_files_versions" {
  type = map(any)
}

variable "reload_data_product_versions" {
  type = map(any)
}

variable "landing_to_raw_versions" {
  type = map(any)
}

variable "create_schema_versions" {
  type = map(any)
}

variable "get_schema_versions" {
  type = map(any)
}

variable "update_metadata_versions" {
  type = map(any)
}

variable "update_schema_versions" {
  type = map(any)
}

variable "preview_data_versions" {
  type = map(any)
}

variable "delete_table_for_data_product_versions" {
  type = map(any)
}
