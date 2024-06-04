variable "application_name" {
  type        = string
  description = "Name of application being protected."
}

variable "monitored_resources" {
  type        = map(string)
  description = "A map of names to ARNs for resources to be included by AWS Shield."
}
