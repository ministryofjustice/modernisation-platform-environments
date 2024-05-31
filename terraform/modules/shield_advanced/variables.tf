variable "application_name" {
  type        = string
  description = "Name of application being protected."
}

variable "enable_proactive_engagement" {
  type        = bool
  default     = true
  description = "Should AWS Shield proactive engagement be enabled?"
}

variable "monitored_resources" {
  type        = map(string)
  description = "A map of names to ARNs for resources to be included by AWS Shield."
}
