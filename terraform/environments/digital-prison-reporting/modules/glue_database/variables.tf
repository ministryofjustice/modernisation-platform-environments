variable "create" {
  default = true
}

variable "name" {}

variable "description" {
  default = ""
}

variable "catalog" {
  default = ""
}

variable "location_uri" {
  default = ""
}

variable "params" {
  description = "(Optional) A list of key-value pairs that define parameters and properties of the database."
  default     = null
}
