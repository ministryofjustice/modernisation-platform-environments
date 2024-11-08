variable "domain_name" {
  description = "The domain name of the hosted zone"
  type        = string
  default     = "modernisation-platform.service.justice.gov.uk"
}

variable "zone_id" {
  description = "The ID of the Route 53 Hosted Zone"
  type        = string
}

variable "subdomain_name" {
  description = "The subdomain to assign to the chaps EC2 instance (e.g., cdpt-chaps.hq-development)"
  type        = string
  default 
}

variable "environment" {
  description = "deployment environment"
  type        = string
}