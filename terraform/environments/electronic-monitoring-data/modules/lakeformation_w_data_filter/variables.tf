variable "table_filters" {
  description = "Map of names of the tables and filters to apply"
  type        = map(string)
}

variable "database_name" {
  description = "Name of the database the table belongs to"
  type        = string

}

variable "extra_arns" {
  description = "ARNs of admin roles"
  type        = list(string)
}

variable "data_bucket_lf_resource" {
  description = "arn of the lake formation resource for the data bucket"
  type        = string
}

variable "role_arn" {
  description = "Role to grant permissions to"
  type        = string
}
