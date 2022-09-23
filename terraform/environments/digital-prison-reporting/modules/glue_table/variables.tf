variable "glue_table_depends_on" {
  type    = any
  default = []
}

variable "enable_glue_catalog_database" {
  description = "Enable glue catalog database usage"
  default     = false
}

variable "glue_catalog_database_name" {
  description = "The name of the database."
  default     = ""
}

variable "glue_catalog_database_parameters" {
  description = "(Optional) A list of key-value pairs that define parameters and properties of the database."
  default     = null
}

variable "enable_glue_catalog_table" {
  description = "Enable glue catalog table usage"
  default     = false
}

variable "name" {
  description = "Name of the table. For Hive compatibility, this must be entirely lowercase."
  default     = ""
}

variable "glue_catalog_table_database_name" {
  description = "Name of the metadata database where the table metadata resides. For Hive compatibility, this must be all lowercase."
  default     = ""
}

variable "glue_catalog_table_description" {
  description = "(Optional) Description of the table."
  default     = null
}

variable "glue_catalog_table_catalog_id" {
  description = "(Optional) ID of the Glue Catalog and database to create the table in. If omitted, this defaults to the AWS Account ID plus the database name."
  default     = null
}

variable "glue_catalog_table_owner" {
  description = "(Optional) Owner of the table."
  default     = null
}

variable "glue_catalog_table_retention" {
  description = "(Optional) Retention time for this table."
  default     = null
}

variable "glue_catalog_table_partition_keys" {
  description = "(Optional) A list of columns by which the table is partitioned. Only primitive types are supported as partition keys."
  default     = []
}

variable "glue_catalog_table_view_original_text" {
  description = "(Optional) If the table is a view, the original text of the view; otherwise null."
  default     = null
}

variable "glue_catalog_table_view_expanded_text" {
  description = "(Optional) If the table is a view, the expanded text of the view; otherwise null."
  default     = null
}

variable "glue_catalog_table_table_type" {
  description = "(Optional) The type of this table (EXTERNAL_TABLE, VIRTUAL_VIEW, etc.)."
  default     = null
}

variable "glue_catalog_table_parameters" {
  description = "(Optional) Properties associated with this table, as a list of key-value pairs."
  default     = null
}

variable "glue_catalog_table_storage_descriptor" {
  description = "(Optional) A storage descriptor object containing information about the physical storage of this table. You can refer to the Glue Developer Guide for a full explanation of this object."
  default = {
    location                  = null
    input_format              = null
    output_format             = null
    compressed                = null
    number_of_buckets         = null
    bucket_columns            = null
    parameters                = null
    stored_as_sub_directories = null
  }
}