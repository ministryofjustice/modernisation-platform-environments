variable "create_db" {
  default = true
}

variable "name" {}

variable "description" {
  default = ""
}

variable "catalog" {
  default = ""
}

variable "aws_account_id" {}

variable "aws_region" {}

variable "location_uri" {
  default = ""
}

variable "params" {
  description = "(Optional) A list of key-value pairs that define parameters and properties of the database."
  default     = null
}
