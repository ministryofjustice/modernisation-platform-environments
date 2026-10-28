variable "enable_delivery" {
  description = "Enable SFTP requests and queue consumption only after recipient onboarding and interoperability checks."
  type        = bool
  default     = false
}