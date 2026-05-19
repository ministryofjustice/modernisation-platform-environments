variable "identity_provider_arn" {
  type        = string
  description = "Identity provider used to trust AP Compute account"
}

variable "role_name" {
  default = "airflow"
  type    = string
}

variable "data_buckets" {
  type        = list(string)
  description = "List of S3 buckets to grant access to"
}
