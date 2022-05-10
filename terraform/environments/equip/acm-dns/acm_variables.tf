variable "zone_id" {
  description = "Route 53 hosted zone id for domain"
  type        = string
}

variable "domain_name" {
  description = "Domain name for which ACM public certificate is being requestion, may be wildcard"
  type        = string
}

variable "ttl" {
  description = "Time to live (ttl) for CNAME DNS validation record"
  type        = number
  default     = 60
}

variable "subject_alternative_names" {
  description = "List of additional domains that should be added to the issued certificate as subject alternative names"
  type        = list(string)
  default     = []
}
