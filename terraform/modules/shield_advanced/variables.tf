variable "application_name" {
  type        = string
  description = "Name of application being protected."
}

variable "excluded_protections" {
  type        = set(string)
  default     = []
  description = "A list of strings to not associate with the AWS Shield WAF ACL."
}

variable "resources" {
  type        = map(any)
  description = "Map of resource ARNs and optional automatic response actions."
}

variable "waf_acl_rules" {
  type        = map(any)
  description = "A map of values to be used in a dynamic WAF ACL rule block."
}