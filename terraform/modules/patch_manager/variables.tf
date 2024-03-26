variable "environment" {
  type = string
}

variable "application" {
  type = string
}

variable "schedule" {
  type = string
}

variable "predefined_baseline" {
  type    = string
}

variable "operating_system" {
  type = string
  description = "Operating system for baseline"
  validation {
    condition = contains(["WINDOWS", "REDHAT_ENTERPRISE_LINUX"], var.operating_system)
    error_message = "Not a valid operating system"
  }
}

variable "target_tag" {
  type = map(any)
}

locals  {
  os  = replace(lower(var.operating_system),"_","-")
}