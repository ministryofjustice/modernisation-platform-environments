variable "environment" {
  description = "Deployment environment whose file dispatch configuration should be returned."
  type        = string

  validation {
    condition     = contains(["development", "test", "preproduction", "production"], var.environment)
    error_message = "Environment must be development, test, preproduction, or production."
  }
}