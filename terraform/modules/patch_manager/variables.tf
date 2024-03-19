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
  default = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
}

variable "operating_system" {
  type    = string
  default = "WINDOWS"
}

variable "target_tag" {
  type = map(any)
}