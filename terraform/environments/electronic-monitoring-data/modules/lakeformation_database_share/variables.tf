variable "dbs_to_grant" {
  description = "Name of the database the table belongs to"
  type        = set(string)

}

variable "data_bucket_lf_resource" {
  description = "arn of the lake formation resource for the data bucket"
  type        = string
}

variable "role_arn" {
  description = "Role to grant permissions to"
  type        = string
}
