variable "domain_name" {
  default = "example.com"
  type    = string
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "r53_zone_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "validate_certs" {
  type    = bool
  default = true
}
