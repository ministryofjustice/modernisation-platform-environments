variable "environment" {
  type        = string
  description = "The account environment"
}

variable "name" {
  type        = string
  description = "name of the pipeline"
}

variable "database_name" {
  type        = string
  description = "name of the database to load to"
}

variable "path_to_data" {
  type        = string
  description = "path to data in source bucket"
  default     = ""
}

variable "source_data_bucket" {
  type        = object({ arn = string })
  description = "source of the data in s3"
}

variable "athena_dump_bucket" {
  type        = object({ arn = string })
  description = "bucket to dump athena queries into"
}

variable "secret_code" {
  type     = string
  nullable = false
}

variable "oidc_arn" {
  type     = string
  nullable = false
}

variable "cadt_bucket" {
  type        = object({ arn = string })
  description = "bucket for cadt"
}

variable "max_session_duration" {
  type        = number
  description = "max session duration for the role in seconds"
  nullable    = true
  default     = 7200
}

# variable "de_role_arn" {
#   nullable    = false
#   type        = string
#   description = "The arn of the data engineering module"
# }

# variable "data_bucket_lf_resource" {
#   nullable    = false
#   type        = string
#   description = "The arn of the LakeFormation resource where our parquet files are held"
# }

variable "db_exists" {
  default     = false
  type        = bool
  description = "Whether the database exists"
}
