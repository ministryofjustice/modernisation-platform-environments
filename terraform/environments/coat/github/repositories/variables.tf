variable "github_token" {
  type        = string
  description = "Required by the GitHub Terraform provider"
  default     = ""
}

variable "github_owner" {
  type        = string
  description = "Default organisation for the GitHub provider configuration"
  default     = "ministryofjustice"
}
