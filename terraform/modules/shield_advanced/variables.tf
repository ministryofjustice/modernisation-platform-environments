variable "application_name" {
  type        = string
  description = "Name of application being protected."
}

variable "monitored_resources" {
  type        = map(string)
  description = "A map of names to ARNs for resources to be included by AWS Shield."
}

variable "excluded_protections" {
  type        = set(string)
  description = "A list of strings to not associate with the AWS Shield WAF ACL"
}