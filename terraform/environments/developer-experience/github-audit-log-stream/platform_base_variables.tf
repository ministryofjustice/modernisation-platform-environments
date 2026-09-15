variable "networking" {
  type = list(any)
}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "cortex_xsiam_workload_identity" {
  type = object({
    issuer_url      = string
    audience        = string
    service_account = string
  })
  default     = null
  description = "Cortex XSIAM Workload Identity Federation configuration supplied by MIP"
}
