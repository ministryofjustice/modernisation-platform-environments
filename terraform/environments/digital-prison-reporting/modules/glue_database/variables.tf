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
  type    = "map"
  default = {}
}
