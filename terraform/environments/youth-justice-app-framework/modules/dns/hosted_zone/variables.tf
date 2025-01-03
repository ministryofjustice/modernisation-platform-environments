variable "domain_name" {
  default = "example.com"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "project_name" {
}

variable "private_hosted_zone" {
  type    = bool
  default = false
}

variable "vpc" {
  type    = string
  default = ""
}
