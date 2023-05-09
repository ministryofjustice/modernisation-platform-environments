variable "master_username" {
  description = "Username for the master DB user (Required unless a `snapshot_identifier` is provided). Defaults to `awsuser`"
  type        = string
  default     = ""
}

variable "schema" {
  description = "Username for the master DB user (Required unless a `snapshot_identifier` is provided). Defaults to `awsuser`"
  type        = string
  default     = ""
}

variable "catalog_db_name" {
  description = "Username for the master DB user (Required unless a `snapshot_identifier` is provided). Defaults to `awsuser`"
  type        = string
  default     = ""
}

variable "master_username" {
  description = "Username for the master DB user (Required unless a `snapshot_identifier` is provided). Defaults to `awsuser`"
  type        = string
  default     = ""
}

variable "enable_redshift_schema" {
  description = "Enable Schema, Set to True if to Terraform the resource"
  type        = bool
  default     = false    
}

variable "glue_catalog_ext" {
  description = "Enable if it is Glue Catalog Source"
  type        = bool
  default     = false    
}

variable "region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account" {
  description = "AWS Account ID."
  default     = ""
}