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

variable "pod_security_mode" {
  type    = string
  default = null
  validation {
    condition     = var.pod_security_mode == null || contains(["privileged", "baseline", "restricted"], var.pod_security_mode)
    error_message = "pod_security_mode must be one of: privileged, baseline, restricted (or null to omit the label)"
  }
}
