variable "networking" {
  type = list(any)
}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "enable_starter_pack" {
  type        = bool
  default     = true
  description = "Toggle to enable starter pack service"
}
