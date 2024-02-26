variable "environment" {
  type = string
}

variable "application" {
  type = string
}

variable "schedule" {
  type = string
}

variable "approved_patches" {
  type    = list(string)
  default = []
}

variable "predefined_baseline" {
  type    = string
  default = "AWS-WindowsPredefinedPatchBaseline-OS-Applications"
}

variable "use_predefined_baseline" {
  type    = bool
  default = false
}