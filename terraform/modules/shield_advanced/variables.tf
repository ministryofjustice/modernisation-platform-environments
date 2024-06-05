variable "application_name" {
  type        = string
  description = "Name of application being protected."
}

variable "excluded_protections" {
  type        = set(string)
  description = "A list of strings to not associate with the AWS Shield WAF ACL"
}

variable "monitored_resources" {
  type        = map(string)
  description = "A map of names to ARNs for resources to be included by AWS Shield."
}

variable "waf_acl_rules" {
  type        = map(any)
  description = "A map of values to be used in a dynamic WAF ACL rule block"
}