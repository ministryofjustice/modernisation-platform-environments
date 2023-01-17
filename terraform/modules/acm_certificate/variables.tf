variable "name" {
  type        = string
  description = "Name of cert to use in tags.Name"
}

variable "domain_name" {
  type        = string
  description = "Domain name for which the certificate should be issued"
}

variable "subject_alternate_names" {
  type        = list(string)
  description = "Set of domains that should be SANs in the issued certificate"
  default     = []
}

variable "validation" {
  type = map(object({
    account   = optional(string, "self")
    zone_name = string
  }))
  description = "Provider a list of zones to use for DNS validation where the key is the cert domain.  Set account to self, core-vpc or core-network-services"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}
