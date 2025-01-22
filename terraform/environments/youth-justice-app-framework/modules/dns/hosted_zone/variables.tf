variable "domain_name" {
  default = "example.com"
  type    = string
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "project_name" {
  type = string
}

variable "private_hosted_zone" {
  type    = bool
  default = false
}

variable "vpc" {
  type    = string
  default = ""
}
