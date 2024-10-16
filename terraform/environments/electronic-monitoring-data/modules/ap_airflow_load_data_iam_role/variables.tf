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

variable "athena_workgroup" {
  type = object({
    arn = string
  })
  description = "athena workgroup to use"
}

variable "secret_code" {
  type     = string
  nullable = false
}

variable "oidc_arn" {
  type     = string
  nullable = false
}
