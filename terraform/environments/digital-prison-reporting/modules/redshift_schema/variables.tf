variable "master_username" {
  description = "Username for the master DB user (Required unless a `snapshot_identifier` is provided). Defaults to `awsuser`"
  type        = string
  default     = ""
}

variable "schema" {
  description = "Redshift Schema to be Setup, Name"
  type        = string
  default     = ""
}

variable "catalog_db_name" {
  description = "Glue catalog DB Name"
  type        = string
  default     = ""
}

variable "enable_redshift_schema" {
  description = "Enable Schema, Set to True if to Terraform the resource"
  type        = bool
  default     = null    
}

variable "glue_catalog_ext" {
  description = "Enable if it is Glue Catalog Source"
  type        = bool
  default     = null    
}

variable "region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account" {
  description = "AWS Account ID."
  default     = ""
}

variable "master_pass" {}