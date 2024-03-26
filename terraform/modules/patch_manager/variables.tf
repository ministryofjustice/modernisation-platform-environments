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
  description = "Predefined baseline"
  type    = string
  validation {
    condition = contains([
      "AWS-WindowsPredefinedPatchBaseline-OS",
      "AWS-WindowsPredefinedPatchBaseline-OS-Applications",
      "AWS-RedHatDefaultPatchBaseline"
    ], var.operating_system)
    error_message = "Not a valid baseline"
  }
}

variable "operating_system" {
  description = "Operating system for baseline"
  type = string
  validation {
    condition = contains(["WINDOWS", "REDHAT_ENTERPRISE_LINUX"], var.operating_system)
    error_message = "Not a valid operating system"
  }
}

variable "target_tag" {
  description = "Instance tag name and value to target for patching"
  type = map(any)
}

locals  {
  os  = replace(lower(var.operating_system),"_","-")
}