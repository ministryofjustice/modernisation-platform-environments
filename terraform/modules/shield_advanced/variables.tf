variable "application_name" {
  type        = string
  description = "Name of application being protected."
}

variable "enable_proactive_engagement" {
  type        = bool
  default     = true
  description = "Should AWS Shield proactive engagement be enabled?"
}

variable "shielded_resources" {
  type        = map(string)
  description = "A map of names to ARNs for resources to be included by AWS Shield."
}

variable "support_email" {
  type        = string
  description = "Email address for proactive support contacts."
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to be applied to resources."
}