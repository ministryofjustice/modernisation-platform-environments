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

## YJSM Hub Svc Pilot
variable "create_svc_pilot" {
  description = "Create infrastructure for the hub-svc pilot, including ALB and associated resources"
  type        = bool
  default     = true
}
