variable "name" {
  type = string
}

variable "workload" {
  type = string
  validation {
    condition     = contains(["system", "application"], var.workload)
    error_message = "workload must be one of: system, application"
  }
}
