variable "name" {
  type        = string
  description = "Name variable that must be in kebab case (lowercase words separated by hyphens)."
  validation {
    condition     = can(regex("^([a-z]+(-[a-z]+)*)$", var.name))
    error_message = "The name must be in kebab case (lowercase words separated by hyphens)."
  }
}

variable "ssh_key" {
  type = string
}

variable "cidr_blocks" {
  type = list(string)
}

variable "transfer_server" {
  type = string
}

variable "transfer_server_security_group" {
  type = string
}

variable "landing_bucket" {
  type = string
}

variable "landing_bucket_kms_key" {
  type = string
}

variable "supplier_data_kms_key" {
  type = string
}
