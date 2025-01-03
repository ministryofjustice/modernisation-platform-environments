variable "domain_name" {
  default = "example.com"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "r53_zone_id" {
}

variable "project_name" {
}